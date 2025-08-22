package com.example.smart_pad.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;

    private static final AntPathMatcher PM = new AntPathMatcher();

    /**
     * 필터를 스킵할 공개 경로
     * - 로그인/회원가입 API
     * - WebSocket 핸드셰이크
     * - 정적/에러/헬스체크
     *
     * ※ "센서 데이터 API"는 여기 넣지 말 것!
     */
    private static final String[] OPEN = new String[] {
            "/api/auth/**",
            "/ws/**",
            "/actuator/health",
            "/error",
            "/favicon.ico",
            "/",
            "/index.html",
            "/static/**",
    };

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        // CORS preflight는 스킵
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) return true;

        final String path = request.getRequestURI();
        for (String p : OPEN) {
            if (PM.match(p, path)) return true; // 공개 경로는 필터 자체를 스킵
        }
        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        try {
            // 이미 컨텍스트에 인증이 있다면 재설정 불필요
            if (SecurityContextHolder.getContext().getAuthentication() == null) {
                final String token = resolveToken(request);
                if (StringUtils.hasText(token) && jwtTokenProvider.validateToken(token)) {
                    final var principal   = jwtTokenProvider.getUserDetails(token);
                    final var authorities = jwtTokenProvider.getAuthorities(token);

                    final var auth = new UsernamePasswordAuthenticationToken(principal, null, authorities);
                    auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(auth);
                }
            }
        } catch (Exception e) {
            // 토큰 파싱/검증 중 오류가 나더라도 여기서 응답을 끊지 않고,
            // AccessDecision(인가)에서 401/403을 판단하도록 체인을 계속 진행한다.
            // 필요하면 로깅 추가:
            // log.warn("JWT filter error: {}", e.getMessage());
        }

        filterChain.doFilter(request, response);
    }

    private String resolveToken(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (!StringUtils.hasText(header)) return null;

        // "Bearer <token>" 형태만 허용 (대소문자/공백 방어)
        header = header.trim();
        if (header.length() < 8) return null;
        final String prefix = "Bearer ";
        if (header.regionMatches(true, 0, prefix, 0, prefix.length())) {
            return header.substring(prefix.length()).trim();
        }
        return null;
    }
}

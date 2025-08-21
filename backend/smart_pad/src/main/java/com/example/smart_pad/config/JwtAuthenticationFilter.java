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

    private final JwtTokenProvider jwtTokenProvider; // 이미 프로젝트에 있는 Provider 사용

    private static final AntPathMatcher PM = new AntPathMatcher();
    private static final String[] OPEN = new String[] {
            "/api/auth/**",
            "/api/sensor-data",
            "/api/sensor-data/**",
            "/api/sensors/ingest",
            "/error",
            "/favicon.ico"
    };

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) return true;
        String path = request.getRequestURI();
        for (String p : OPEN) if (PM.match(p, path)) return true;  // ★ 오픈 경로는 필터 자체를 스킵
        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String token = resolveToken(request);

        if (StringUtils.hasText(token) && jwtTokenProvider.validateToken(token)) {
            var principal   = jwtTokenProvider.getUserDetails(token);
            var authorities = jwtTokenProvider.getAuthorities(token);

            var auth = new UsernamePasswordAuthenticationToken(principal, null, authorities);
            auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(auth);
        }

        // 토큰이 없거나 무효여도 여기서 401/403을 만들지 않고 다음 필터로 넘김
        filterChain.doFilter(request, response);
    }

    private String resolveToken(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (!StringUtils.hasText(header) || !header.startsWith("Bearer ")) return null;
        return header.substring(7);
    }
}

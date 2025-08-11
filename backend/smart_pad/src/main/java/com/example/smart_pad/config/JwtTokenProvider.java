package com.example.smart_pad.config;

import com.example.smart_pad.domain.User;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Collection;
import java.util.Date;
import java.util.List;

@Component
public class JwtTokenProvider {

    private final Key key;
    // 만료시간: 24시간 (원하면 @Value 로 빼도 됨)
    private static final long TOKEN_VALIDITY_MS = 1000L * 60 * 60 * 24;

    public JwtTokenProvider(@Value("${jwt.secret}") String secretKey) {
        // HS256용 키 생성 (32바이트 이상 권장)
        this.key = Keys.hmacShaKeyFor(secretKey.getBytes(StandardCharsets.UTF_8));
    }

    /** 로그인 성공 시 토큰 생성 */
    public String createToken(User user) {
        Date now = new Date();
        Claims claims = Jwts.claims().setSubject(user.getUsername());
        claims.put("userId", user.getId());             // 선택: 필요하면 사용
        claims.put("name", user.getName());             // 선택
        claims.put("role", user.getRole().name());      // 예: PATIENT / ADMIN

        return Jwts.builder()
                .setClaims(claims)
                .setIssuedAt(now)
                .setExpiration(new Date(now.getTime() + TOKEN_VALIDITY_MS))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    /** 토큰 유효성 검증 */
    public boolean validateToken(String token) {
        try {
            parser().parseClaimsJws(token); // 서명/만료/구조 검증
            return true;
        } catch (ExpiredJwtException e) {
            // 만료
            return false;
        } catch (JwtException | IllegalArgumentException e) {
            // 서명 불일치, 형식 오류 등
            return false;
        }
    }

    /** Username (subject) 추출 */
    public String getUsername(String token) {
        return getAllClaims(token).getSubject();
    }

    /** 권한 목록 추출 (JWT의 role 클레임 기반) */
    public Collection<? extends GrantedAuthority> getAuthorities(String token) {
        String role = (String) getAllClaims(token).get("role");
        // Spring Security 규칙에 맞춰 ROLE_ 접두사 권장
        return List.of(new SimpleGrantedAuthority("ROLE_" + role));
    }

    /** Spring Security에서 사용할 UserDetails 생성 */
    public UserDetails getUserDetails(String token) {
        String username = getUsername(token);
        Collection<? extends GrantedAuthority> authorities = getAuthorities(token);
        // 비밀번호는 토큰 검증 단계에선 필요 없음 -> 빈 문자열
        return new org.springframework.security.core.userdetails.User(username, "", authorities);
    }

    /** (선택) name / userId 등 추가 클레임 필요시 꺼내서 사용 */
    public Long getUserId(String token) {
        Object v = getAllClaims(token).get("userId");
        if (v == null) return null;
        if (v instanceof Integer i) return i.longValue();
        if (v instanceof Long l) return l;
        if (v instanceof String s) {
            try { return Long.parseLong(s); } catch (NumberFormatException ignored) {}
        }
        return null;
    }

    public String getName(String token) {
        Object v = getAllClaims(token).get("name");
        return v != null ? v.toString() : null;
    }

    // ===== 내부 유틸 =====

    private JwtParser parser() {
        return Jwts.parserBuilder().setSigningKey(key).build();
    }

    private Claims getAllClaims(String token) {
        return parser().parseClaimsJws(token).getBody();
    }
}

package com.example.smart_pad.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable()) // CSRF 보호 비활성화 (API 서버이므로)
                .httpBasic(httpBasic -> httpBasic.disable()) // 기본 인증 비활성화
                .formLogin(formLogin -> formLogin.disable()) // 폼 로그인 비활성화
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)) // 세션 사용 안함 (JWT 사용)
                .authorizeHttpRequests(auth -> auth
                        // "/api/auth/**" 경로는 누구나 접근 가능하도록 허용
                        .requestMatchers("/api/auth/**").permitAll()
                        // 나머지 모든 요청은 인증 필요 (나중에 설정)
                        .anyRequest().authenticated()
                );

        return http.build();
    }
}

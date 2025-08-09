package com.example.smart_pad.controller;

import com.example.smart_pad.controller.dto.LoginRequest;
import com.example.smart_pad.controller.dto.SignUpRequest;
import com.example.smart_pad.service.AuthService;
import jakarta.validation.Valid; // 1. @Valid 어노테이션을 사용하기 위해 import 합니다.
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/auth") // 이 클래스의 모든 API 경로는 "/api/auth"로 시작됩니다.
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /**
     * 회원가입 API
     * POST /api/auth/signup
     */
    @PostMapping("/signup")
    // --- [핵심] ---
    // @RequestBody 앞에 @Valid 어노테이션을 추가합니다.
    // 이렇게 하면, Spring이 SignUpRequest 객체를 만들기 전에
    // DTO 내부에 정의된 유효성 검사 규칙(@NotBlank, @Size 등)을 먼저 실행합니다.
    public ResponseEntity<String> signup(@Valid @RequestBody SignUpRequest request) {
        // 유효성 검사를 통과한 경우에만 아래 로직이 실행됩니다.
        // 통과하지 못하면 Spring이 자동으로 400 Bad Request 에러를 응답합니다.
        authService.signup(request.getUsername(), request.getPassword(), request.getName(), request.getRole());

        // 성공 시, HTTP 상태 코드 200 (OK)와 함께 성공 메시지를 응답합니다.
        return ResponseEntity.ok("회원가입이 성공적으로 완료되었습니다.");
    }

    /**
     * 로그인 API
     * POST /api/auth/login
     */
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody LoginRequest request) {
        // 로그인 요청은 DTO에 별도의 유효성 검사 규칙을 넣지 않았으므로 @Valid가 필요 없습니다.
        // (아이디나 비밀번호가 없는 요청은 서비스 로직에서 처리)
        Map<String, Object> response = authService.login(request.getUsername(), request.getPassword());

        // 성공 시, HTTP 상태 코드 200 (OK)와 함께 JWT 토큰과 사용자 정보가 담긴 Map을 응답합니다.
        return ResponseEntity.ok(response);
    }
}

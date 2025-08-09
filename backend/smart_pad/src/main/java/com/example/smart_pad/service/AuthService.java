package com.example.smart_pad.service;

import com.example.smart_pad.config.JwtTokenProvider; // JWT 프로바이더 import
import com.example.smart_pad.domain.User;
import com.example.smart_pad.domain.UserRole;
import com.example.smart_pad.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException; // 로그인 실패 예외
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider; // 1. JwtTokenProvider를 의존성으로 주입받습니다.

    /**
     * 회원가입 로직
     */
    @Transactional
    public void signup(String username, String password, String name, UserRole role) {
        // 아이디 중복 확인
        if (userRepository.findByUsername(username).isPresent()) {
            throw new IllegalArgumentException("이미 사용 중인 아이디입니다.");
        }

        // 비밀번호 암호화
        String encodedPassword = passwordEncoder.encode(password);

        User user = User.builder()
                .username(username)
                .password(encodedPassword)
                .name(name)
                .role(role)
                .build();

        userRepository.save(user);
    }

    /**
     * 로그인 로직
     * @return Map<String, Object> - JWT 토큰과 사용자 정보를 포함하는 맵
     */
    @Transactional(readOnly = true) // 데이터 변경이 없으므로 읽기 전용으로 설정
    public Map<String, Object> login(String username, String password) {
        // 1. 아이디(username)를 기반으로 DB에서 사용자 정보를 조회합니다.
        //    orElseThrow: 사용자가 없으면 예외(Exception)를 발생시킵니다.
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("가입되지 않은 아이디입니다."));

        // 2. 입력받은 비밀번호와 DB에 암호화되어 저장된 비밀번호가 일치하는지 확인합니다.
        //    passwordEncoder.matches()가 이 비교 과정을 안전하게 처리해 줍니다.
        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new BadCredentialsException("비밀번호가 일치하지 않습니다.");
        }

        // 3. 아이디와 비밀번호가 모두 일치하면, JwtTokenProvider를 사용해 JWT 토큰을 생성합니다.
        String token = jwtTokenProvider.createToken(user);

        // 4. 프론트엔드(Flutter 앱)로 보낼 응답 데이터를 구성합니다.
        //    Map을 사용하면 JSON 객체 형태로 변환하기 용이합니다.
        Map<String, Object> response = new HashMap<>();
        response.put("token", token); // 생성된 JWT 토큰
        response.put("user", user);   // 로그인한 사용자의 정보 (id, username, name, role)

        // 5. 토큰과 사용자 정보가 담긴 Map을 반환합니다.
        return response;
    }
}

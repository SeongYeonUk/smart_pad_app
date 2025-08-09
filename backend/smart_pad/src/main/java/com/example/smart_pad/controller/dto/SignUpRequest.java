package com.example.smart_pad.controller.dto;

import com.example.smart_pad.domain.UserRole;
// 1. jakarta.validation 패키지에서 필요한 어노테이션들을 import 합니다.
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SignUpRequest {

    // --- 아이디(username) 유효성 검사 ---
    @NotBlank(message = "아이디는 필수 입력 값입니다.") // null, "", " " (공백만 있는 문자열)을 모두 허용하지 않음
    @Size(max = 12, message = "아이디는 12글자 이하로 설정해주세요.") // 최대 길이를 12자로 제한
    private String username;

    // --- 비밀번호(password) 유효성 검사 ---
    @NotBlank(message = "비밀번호는 필수 입력 값입니다.")
    @Size(max = 12, message = "비밀번호는 12글자 이하로 설정해주세요.")
    // 정규 표현식(Regular Expression)을 사용하여 비밀번호 규칙을 정의
    // ^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{1,12}$
    // - (?=.*[A-Za-z]): 최소 한 개의 영문자가 포함되어야 함
    // - (?=.*\d): 최소 한 개의 숫자가 포함되어야 함
    // - [A-Za-z\d]{1,12}: 영문자와 숫자로만 구성되며, 길이는 1~12자
    @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{1,12}$", message = "비밀번호는 영어와 숫자를 반드시 포함해야 합니다.")
    private String password;

    // --- 이름(name) 유효성 검사 ---
    @NotBlank(message = "이름은 필수 입력 값입니다.")
    private String name;

    // --- 역할(role) 유효성 검사 ---
    @NotNull(message = "사용자 역할은 필수 선택 값입니다.") // Enum 타입이므로 NotBlank 대신 NotNull 사용
    private UserRole role;
}

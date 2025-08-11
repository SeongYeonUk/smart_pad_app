package com.example.smart_pad.controller.dto;

import com.example.smart_pad.domain.UserRole;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

// 환자 상세 정보 DTO를 사용하기 위해 import 합니다.
import com.example.smart_pad.controller.dto.PatientDetailDto;
// ▼▼▼ 관리자 상세 정보 DTO를 사용하기 위해 import 합니다. ▼▼▼
import com.example.smart_pad.controller.dto.AdminDetailDto;

@Getter
@Setter
public class SignUpRequest {

    // --- 아이디(username) 유효성 검사 ---
    @NotBlank(message = "아이디는 필수 입력 값입니다.")
    @Size(max = 12, message = "아이디는 12글자 이하로 설정해주세요.")
    private String username;

    // --- 비밀번호(password) 유효성 검사 ---
    @NotBlank(message = "비밀번호는 필수 입력 값입니다.")
    @Size(max = 12, message = "비밀번호는 12글자 이하로 설정해주세요.")
    @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{1,12}$", message = "비밀번호는 영어와 숫자를 반드시 포함해야 합니다.")
    private String password;

    // --- 이름(name) 유효성 검사 ---
    @NotBlank(message = "이름은 필수 입력 값입니다.")
    private String name;

    // --- 역할(role) 유효성 검사 ---
    @NotNull(message = "사용자 역할은 필수 선택 값입니다.")
    private UserRole role;

    // 환자 상세 정보를 담을 필드
    private PatientDetailDto patientDetail;

    // ▼▼▼ 여기에 관리자 상세 정보를 담을 필드를 추가합니다. ▼▼▼
    private AdminDetailDto adminDetail;
}
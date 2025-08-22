package com.example.smart_pad.service;

import com.example.smart_pad.config.JwtTokenProvider;
import com.example.smart_pad.controller.dto.AdminDetailDto;
import com.example.smart_pad.controller.dto.PatientDetailDto;
import com.example.smart_pad.controller.dto.ProfileDetailResponse;
import com.example.smart_pad.controller.dto.SignUpRequest;
import com.example.smart_pad.controller.dto.UpdateProfileRequest;
import com.example.smart_pad.domain.AdminDetail;
import com.example.smart_pad.domain.PatientDetail;
import com.example.smart_pad.domain.User;
import com.example.smart_pad.domain.UserRole;
import com.example.smart_pad.repository.AdminDetailRepository;
import com.example.smart_pad.repository.PatientDetailRepository;
import com.example.smart_pad.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final PatientDetailRepository patientDetailRepository;
    private final AdminDetailRepository adminDetailRepository;

    /**
     * 회원가입
     * - username 중복 체크
     * - 비밀번호 해시
     * - 역할(PATIENT/ADMIN)에 따라 Detail 엔티티 생성
     */
    @Transactional
    public void signup(SignUpRequest request) {
        final String username = safeTrim(request.getUsername());
        if (username == null || username.isEmpty()) {
            throw new IllegalArgumentException("아이디를 입력해주세요.");
        }
        if (userRepository.findByUsername(username).isPresent()) {
            throw new IllegalArgumentException("이미 사용 중인 아이디입니다.");
        }

        final String rawPassword = request.getPassword();
        if (rawPassword == null || rawPassword.isBlank()) {
            throw new IllegalArgumentException("비밀번호를 입력해주세요.");
        }

        String encodedPassword = passwordEncoder.encode(rawPassword);

        User user = User.builder()
                .username(username)
                .password(encodedPassword)
                .name(safeTrim(request.getName()))
                .role(request.getRole())
                .build();

        User savedUser = userRepository.save(user);

        if (savedUser.getRole() == UserRole.PATIENT) {
            PatientDetailDto dto = request.getPatientDetail();
            if (dto != null) {
                PatientDetail detail = new PatientDetail();
                detail.setUser(savedUser);
                detail.setWeight(dto.getWeight());
                detail.setAgeRange(dto.getAgeRange());
                detail.setSensoryPerception(dto.getSensoryPerception());
                detail.setActivityLevel(dto.getActivityLevel());
                detail.setMovementLevel(dto.getMovementLevel());
                patientDetailRepository.save(detail);
            }
        } else if (savedUser.getRole() == UserRole.ADMIN) {
            AdminDetailDto dto = request.getAdminDetail();
            if (dto != null) {
                AdminDetail detail = new AdminDetail();
                detail.setUser(savedUser);
                detail.setHospitalName(dto.getHospitalName());
                adminDetailRepository.save(detail);
            }
        }
    }

    /**
     * 로그인
     * - 아이디/비밀번호 검증
     * - JWT 생성 후 {"token": "...", "user": <필요정보>} 반환
     */
    @Transactional(readOnly = true)
    public Map<String, Object> login(String username, String password) {
        final String uname = safeTrim(username);
        if (uname == null || uname.isEmpty()) {
            throw new IllegalArgumentException("아이디를 입력해주세요.");
        }
        if (password == null || password.isBlank()) {
            throw new BadCredentialsException("비밀번호를 입력해주세요.");
        }

        User user = userRepository.findByUsername(uname)
                .orElseThrow(() -> new IllegalArgumentException("가입되지 않은 아이디입니다."));

        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new BadCredentialsException("비밀번호가 일치하지 않습니다.");
        }

        String token = jwtTokenProvider.createToken(user);

        Map<String, Object> response = new HashMap<>();
        response.put("token", token);
        // 필요 시 user 전체를 내보내지 말고 필요한 최소 필드만 DTO로 내려도 됨
        response.put("user", user);
        return response;
    }

    /**
     * 사용자 삭제
     * - 역할에 맞는 상세 엔티티부터 제거 후 사용자 삭제
     */
    @Transactional
    public void deleteUser(String username) {
        final String uname = safeTrim(username);
        User user = userRepository.findByUsername(uname)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        if (user.getRole() == UserRole.PATIENT) {
            patientDetailRepository.findByUser_Id(user.getId())
                    .ifPresent(patientDetailRepository::delete);
        } else if (user.getRole() == UserRole.ADMIN) {
            adminDetailRepository.findByUser_Id(user.getId())
                    .ifPresent(adminDetailRepository::delete);
        }

        userRepository.delete(user);
    }

    /**
     * 환자 프로필 조회 (환자 상세 없으면 사용자 기본 정보만 반환)
     */
    @Transactional(readOnly = true)
    public Optional<ProfileDetailResponse> fetchPatientDetail(Long userId) {
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) return Optional.empty();

        User user = userOpt.get();
        return patientDetailRepository.findByUser_Id(userId)
                .map(pd -> ProfileDetailResponse.builder()
                        .id(user.getId())
                        .name(user.getName())
                        .weight(pd.getWeight())
                        .ageRange(pd.getAgeRange())
                        .sensoryPerception(pd.getSensoryPerception())
                        .activityLevel(pd.getActivityLevel())
                        .movementLevel(pd.getMovementLevel())
                        .build())
                .or(() -> Optional.of(ProfileDetailResponse.builder()
                        .id(user.getId())
                        .name(user.getName())
                        .build()));
    }

    /**
     * 관리자 프로필 조회 (관리자 상세 없으면 사용자 기본 정보만 반환)
     */
    @Transactional(readOnly = true)
    public Optional<ProfileDetailResponse> fetchAdminDetail(Long userId) {
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) return Optional.empty();

        User user = userOpt.get();
        return adminDetailRepository.findByUser_Id(userId)
                .map(ad -> ProfileDetailResponse.builder()
                        .id(user.getId())
                        .name(user.getName())
                        .hospitalName(ad.getHospitalName())
                        .build())
                .or(() -> Optional.of(ProfileDetailResponse.builder()
                        .id(user.getId())
                        .name(user.getName())
                        .build()));
    }

    /**
     * 프로필 업데이트(부분 업데이트 + NPE 방지)
     * - 이름은 공백 문자열이면 무시
     * - 역할에 따라 상세 엔티티 upsert
     */
    @Transactional
    public void updateProfile(Long userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        if (request.getName() != null) {
            String newName = safeTrim(request.getName());
            if (newName != null && !newName.isEmpty()) {
                user.setName(newName);
                userRepository.save(user);
            }
        }

        if (user.getRole() == UserRole.PATIENT) {
            PatientDetailDto dto = request.getPatientDetail();
            if (dto != null) {
                PatientDetail detail = patientDetailRepository.findByUser_Id(userId)
                        .orElseGet(() -> {
                            PatientDetail pd = new PatientDetail();
                            pd.setUser(user);
                            return pd;
                        });

                if (dto.getWeight() != null) detail.setWeight(dto.getWeight());
                if (dto.getAgeRange() != null) detail.setAgeRange(dto.getAgeRange());
                if (dto.getSensoryPerception() != null) detail.setSensoryPerception(dto.getSensoryPerception());
                if (dto.getActivityLevel() != null) detail.setActivityLevel(dto.getActivityLevel());
                if (dto.getMovementLevel() != null) detail.setMovementLevel(dto.getMovementLevel());

                patientDetailRepository.save(detail);
            }
        } else if (user.getRole() == UserRole.ADMIN) {
            AdminDetailDto dto = request.getAdminDetail();
            if (dto != null) {
                AdminDetail detail = adminDetailRepository.findByUser_Id(userId)
                        .orElseGet(() -> {
                            AdminDetail ad = new AdminDetail();
                            ad.setUser(user);
                            return ad;
                        });

                if (dto.getHospitalName() != null) detail.setHospitalName(dto.getHospitalName());
                adminDetailRepository.save(detail);
            }
        }
    }

    /**
     * Authentication → 현재 로그인한 사용자 ID
     * - SecurityContext에 세팅된 principal의 username을 기반으로 조회
     */
    @Transactional(readOnly = true)
    public Long getUserIdFromAuthentication(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new IllegalArgumentException("인증 정보가 없습니다.");
        }
        String username = authentication.getName();
        return userRepository.findByUsername(username)
                .map(User::getId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }

    /**
     * 로그인 사용자 ID로 PatientDetail 조회 (없으면 예외)
     */
    @Transactional(readOnly = true)
    public PatientDetail getPatientDetailById(Long userId) {
        return patientDetailRepository.findByUser_Id(userId)
                .orElseThrow(() -> new IllegalArgumentException("환자 정보를 찾을 수 없습니다."));
    }

    /**
     * (유틸) 공백/널 안전 트림
     */
    private String safeTrim(String s) {
        return (s == null) ? null : s.trim();
    }
}

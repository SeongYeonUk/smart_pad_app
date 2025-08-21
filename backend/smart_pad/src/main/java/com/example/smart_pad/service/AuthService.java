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

    @Transactional
    public void signup(SignUpRequest request) {
        if (userRepository.findByUsername(request.getUsername()).isPresent()) {
            throw new IllegalArgumentException("이미 사용 중인 아이디입니다.");
        }

        String encodedPassword = passwordEncoder.encode(request.getPassword());

        User user = User.builder()
                .username(request.getUsername())
                .password(encodedPassword)
                .name(request.getName())
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

    @Transactional(readOnly = true)
    public Map<String, Object> login(String username, String password) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("가입되지 않은 아이디입니다."));

        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new BadCredentialsException("비밀번호가 일치하지 않습니다.");
        }

        String token = jwtTokenProvider.createToken(user);

        Map<String, Object> response = new HashMap<>();
        response.put("token", token);
        response.put("user", user);
        return response;
    }

    @Transactional
    public void deleteUser(String username) {
        User user = userRepository.findByUsername(username)
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

    @Transactional(readOnly = true)
    public Optional<ProfileDetailResponse> fetchPatientDetail(Long userId) {
        Optional<User> user = userRepository.findById(userId);
        if (user.isEmpty()) {
            return Optional.empty();
        }

        return patientDetailRepository.findByUser_Id(userId)
                .map(pd -> ProfileDetailResponse.builder()
                        .id(user.get().getId())
                        .name(user.get().getName())
                        .weight(pd.getWeight())
                        .ageRange(pd.getAgeRange())
                        .sensoryPerception(pd.getSensoryPerception())
                        .activityLevel(pd.getActivityLevel())
                        .movementLevel(pd.getMovementLevel())
                        .build())
                .or(() -> Optional.of(ProfileDetailResponse.builder()
                        .id(user.get().getId())
                        .name(user.get().getName())
                        .build()));
    }

    @Transactional(readOnly = true)
    public Optional<ProfileDetailResponse> fetchAdminDetail(Long userId) {
        Optional<User> user = userRepository.findById(userId);
        if (user.isEmpty()) {
            return Optional.empty();
        }

        return adminDetailRepository.findByUser_Id(userId)
                .map(ad -> ProfileDetailResponse.builder()
                        .id(user.get().getId())
                        .name(user.get().getName())
                        .hospitalName(ad.getHospitalName())
                        .build())
                .or(() -> Optional.of(ProfileDetailResponse.builder()
                        .id(user.get().getId())
                        .name(user.get().getName())
                        .build()));
    }

    // ★ 부분 업데이트 + NPE 방지
    @Transactional
    public void updateProfile(Long userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        if (request.getName() != null) {
            user.setName(request.getName());
            userRepository.save(user);
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
     * Authentication으로부터 현재 로그인한 사용자 ID 반환
     */
    @Transactional(readOnly = true)
    public Long getUserIdFromAuthentication(Authentication authentication) {
        String username = authentication.getName();
        return userRepository.findByUsername(username)
                .map(User::getId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }

    /**
     * 로그인 사용자 ID로 PatientDetail 조회
     * - 파라미터명은 patientId가 아니라 userId에 해당함
     */
    @Transactional(readOnly = true)
    public PatientDetail getPatientDetailById(Long userId) {
        return patientDetailRepository.findByUser_Id(userId)
                .orElseThrow(() -> new IllegalArgumentException("환자 정보를 찾을 수 없습니다."));
    }
}

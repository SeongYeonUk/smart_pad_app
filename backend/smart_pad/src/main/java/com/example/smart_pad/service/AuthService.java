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
            PatientDetailDto patientDetailDto = request.getPatientDetail();
            if (patientDetailDto != null) {
                PatientDetail patientDetail = new PatientDetail();
                patientDetail.setUser(savedUser);
                patientDetail.setWeight(patientDetailDto.getWeight());
                patientDetail.setAgeRange(patientDetailDto.getAgeRange());
                patientDetail.setSensoryPerception(patientDetailDto.getSensoryPerception());
                patientDetail.setActivityLevel(patientDetailDto.getActivityLevel());
                patientDetail.setMovementLevel(patientDetailDto.getMovementLevel());
                patientDetailRepository.save(patientDetail);
            }
        } else if (savedUser.getRole() == UserRole.ADMIN) {
            AdminDetailDto adminDetailDto = request.getAdminDetail();
            if (adminDetailDto != null) {
                AdminDetail adminDetail = new AdminDetail();
                adminDetail.setUser(savedUser);
                adminDetail.setHospitalName(adminDetailDto.getHospitalName());
                adminDetailRepository.save(adminDetail);
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
            patientDetailRepository.findByUserId(user.getId())
                    .ifPresent(patientDetailRepository::delete);
        } else if (user.getRole() == UserRole.ADMIN) {
            adminDetailRepository.findByUserId(user.getId())
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

        return patientDetailRepository.findByUserId(userId)
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

        return adminDetailRepository.findByUserId(userId)
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

    // ★★★ 핵심: 부분 업데이트 + NPE 방지
    @Transactional
    public void updateProfile(Long userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 이름 부분 업데이트
        if (request.getName() != null) {
            user.setName(request.getName());
            userRepository.save(user);
        }

        if (user.getRole() == UserRole.PATIENT) {
            PatientDetailDto dto = request.getPatientDetail();
            if (dto != null) {
                PatientDetail detail = patientDetailRepository.findByUserId(userId)
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
                AdminDetail detail = adminDetailRepository.findByUserId(userId)
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
}

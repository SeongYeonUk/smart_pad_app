package com.example.smart_pad.controller;

import com.example.smart_pad.controller.dto.ProfileDetailResponse;
import com.example.smart_pad.controller.dto.UpdateProfileRequest;
import com.example.smart_pad.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class UserController {

    private final AuthService authService;

    /**
     * 특정 환자의 상세 정보를 조회하는 API
     * GET /api/patient_detail/{userId}
     */
    @GetMapping("/patient_detail/{userId}")
    public ResponseEntity<ProfileDetailResponse> getPatientDetail(@PathVariable Long userId) {
        Optional<ProfileDetailResponse> patientDetail = authService.fetchPatientDetail(userId);

        // ▼▼▼ Optional이 비어있을 경우, 200 OK와 함께 빈 DTO 객체를 반환합니다. ▼▼▼
        return patientDetail.map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.ok(ProfileDetailResponse.builder().build()));
    }

    /**
     * 특정 관리자의 상세 정보를 조회하는 API
     * GET /api/admin_detail/{userId}
     */
    @GetMapping("/admin_detail/{userId}")
    public ResponseEntity<ProfileDetailResponse> getAdminDetail(@PathVariable Long userId) {
        Optional<ProfileDetailResponse> adminDetail = authService.fetchAdminDetail(userId);

        // ▼▼▼ Optional이 비어있을 경우, 200 OK와 함께 빈 DTO 객체를 반환합니다. ▼▼▼
        return adminDetail.map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.ok(ProfileDetailResponse.builder().build()));
    }

    /**
     * 사용자의 프로필 정보를 업데이트하는 API
     * PUT /api/users/{userId}
     */
    @PutMapping("/users/{userId}")
    public ResponseEntity<String> updateProfile(@PathVariable Long userId,
                                                @RequestBody UpdateProfileRequest request) {
        try {
            authService.updateProfile(userId, request);
            return ResponseEntity.ok("프로필 정보가 성공적으로 업데이트되었습니다.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("프로필 업데이트 중 오류가 발생했습니다.");
        }
    }
}

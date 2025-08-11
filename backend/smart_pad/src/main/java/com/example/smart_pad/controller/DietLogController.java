// DietLogController.java
package com.example.smart_pad.controller;

import com.example.smart_pad.controller.dto.DietLogRequest;
import com.example.smart_pad.controller.dto.DietLogResponse;
import com.example.smart_pad.service.DietLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/diet")
@RequiredArgsConstructor
public class DietLogController {

    private final DietLogService dietLogService;

    // ✅ 생성 후 생성된 DTO(JSON) 반환
    @PostMapping("/{userId}")
    public ResponseEntity<?> saveDietLog(@PathVariable Long userId,
                                         @RequestBody DietLogRequest request) {
        try {
            DietLogResponse created = dietLogService.saveDietLogAndReturnDto(userId, request);
            return ResponseEntity.status(HttpStatus.CREATED).body(created);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("식단 기록 저장 중 오류가 발생했습니다.");
        }
    }

    @GetMapping("/{userId}")
    public ResponseEntity<?> getDietLogs(@PathVariable Long userId) {
        try {
            return ResponseEntity.ok(dietLogService.getDietLogs(userId));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("식단 기록 조회 중 오류가 발생했습니다.");
        }
    }
}

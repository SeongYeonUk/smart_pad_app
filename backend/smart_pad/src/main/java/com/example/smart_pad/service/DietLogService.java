package com.example.smart_pad.service;

import com.example.smart_pad.controller.dto.DietLogRequest;
import com.example.smart_pad.controller.dto.DietLogResponse;
import com.example.smart_pad.domain.DietLog;
import com.example.smart_pad.domain.User;
import com.example.smart_pad.repository.DietLogRepository;
import com.example.smart_pad.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DietLogService {

    private final DietLogRepository dietLogRepository;
    private final UserRepository userRepository;

    /**
     * 식단 기록 생성 또는 수정
     * 요청에 ID가 있으면 수정, 없으면 새로 생성
     */
    @Transactional
    public DietLogResponse createOrUpdateDietLog(DietLogRequest request) {
        DietLog dietLog;
        if (request.getId() != null) {
            // 수정 로직
            dietLog = dietLogRepository.findById(request.getId())
                    .orElseThrow(() -> new IllegalArgumentException("식단 기록을 찾을 수 없습니다."));
            dietLog.setDate(request.getDate());
            dietLog.setMealType(request.getMealType());
            dietLog.setMainDish(request.getMainDish());
            dietLog.setSubDish(request.getSubDish());
            dietLog.setProteinGrams(request.getProteinGrams());
        } else {
            // 생성 로직
            User user = userRepository.findById(request.getUserId())
                    .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
            dietLog = new DietLog();
            dietLog.setUser(user);
            dietLog.setDate(request.getDate());
            dietLog.setMealType(request.getMealType());
            dietLog.setMainDish(request.getMainDish());
            dietLog.setSubDish(request.getSubDish());
            dietLog.setProteinGrams(request.getProteinGrams());
        }

        DietLog savedLog = dietLogRepository.save(dietLog);
        return DietLogResponse.builder()
                .id(savedLog.getId())
                .date(savedLog.getDate())
                .mealType(savedLog.getMealType())
                .mainDish(savedLog.getMainDish())
                .subDish(savedLog.getSubDish())
                .proteinGrams(savedLog.getProteinGrams())
                .build();
    }

    /**
     * 특정 사용자의 모든 식단 기록 조회
     */
    @Transactional(readOnly = true)
    public List<DietLogResponse> getDietLogs(Long userId) {
        List<DietLog> dietLogs = dietLogRepository.findByUserIdOrderByDateDesc(userId);

        return dietLogs.stream()
                .map(log -> DietLogResponse.builder()
                        .id(log.getId())
                        .date(log.getDate())
                        .mealType(log.getMealType())
                        .mainDish(log.getMainDish())
                        .subDish(log.getSubDish())
                        .proteinGrams(log.getProteinGrams())
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * 식단 기록 삭제
     */
    @Transactional
    public void deleteDietLog(Long logId) {
        dietLogRepository.deleteById(logId);
    }
}

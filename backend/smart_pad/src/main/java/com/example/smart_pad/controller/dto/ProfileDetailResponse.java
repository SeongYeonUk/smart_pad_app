package com.example.smart_pad.controller.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor // Lombok이 기본 생성자를 만들어줍니다.
@AllArgsConstructor // 모든 필드를 포함한 생성자를 만들어줍니다.
public class ProfileDetailResponse {
    private Long id;
    private String name;

    private Double weight;
    private String ageRange;
    private String sensoryPerception;
    private String activityLevel;
    private String movementLevel;

    private String hospitalName;
}

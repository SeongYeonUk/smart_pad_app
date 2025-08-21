package com.example.smart_pad.controller.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class DietLogResponse {
    private Long id;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    private LocalDate date;

    private String mealType;
    private String mainDish;
    private String subDish;
    private Integer proteinGrams; // 단백질량 필드 추가
}

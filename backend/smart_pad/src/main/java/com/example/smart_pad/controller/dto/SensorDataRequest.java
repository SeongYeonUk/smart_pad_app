// src/main/java/com/example/smart_pad/controller/dto/SensorDataRequest.java
package com.example.smart_pad.controller.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true) // payload의 여분 키(pressure_voltage 등) 무시
public class SensorDataRequest {

    // (선택) 바디로도 환자 지정 가능
    private Long patientId;

    // ESP32의 pressure_raw(정수)를 pressure로 매핑
    @NotNull
    @JsonAlias({"pressure_raw", "pressure"})
    private Integer pressure;

    // ESP32가 소수로 보내므로 Double로 수신
    @NotNull
    private Double temperature;

    @NotNull
    private Double humidity;
}

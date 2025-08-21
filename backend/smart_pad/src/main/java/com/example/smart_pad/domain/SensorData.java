package com.example.smart_pad.domain;

import jakarta.persistence.*;   // ✅ javax → jakarta 로 변경
import java.time.LocalDateTime;

@Entity
@Table(name = "sensor_data")
public class SensorData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Integer pressure;
    private Integer temperature;
    private Integer humidity;

    private LocalDateTime timestamp;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "patient_id")
    private PatientDetail patient;

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getPressure() { return pressure; }
    public void setPressure(Integer pressure) { this.pressure = pressure; }

    public Integer getTemperature() { return temperature; }
    public void setTemperature(Integer temperature) { this.temperature = temperature; }

    public Integer getHumidity() { return humidity; }
    public void setHumidity(Integer humidity) { this.humidity = humidity; }

    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }

    public PatientDetail getPatient() { return patient; }
    public void setPatient(PatientDetail patient) { this.patient = patient; }
}

package com.example.smart_pad.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "diet_log")
@Getter
@Setter
@NoArgsConstructor
public class DietLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "date", nullable = false)
    private LocalDate date;

    @Column(name = "meal_type", nullable = false)
    private String mealType;

    @Column(name = "main_dish", nullable = false)
    private String mainDish;

    @Column(name = "sub_dish")
    private String subDish;
}

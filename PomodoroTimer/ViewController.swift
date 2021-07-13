//
//  ViewController.swift
//  PomodoroTimer
//
//  Created by Oleg Kirsanov on 09.07.2021.
//

import UIKit

class ViewController: UIViewController {
    
    var timer = Timer()
    var timeLeft: TimeInterval = Metric.workTime
    var endTime: Date?
    var isTimerOn = false
    var isWorkTime = true
    
    let mainShape = CAShapeLayer()
    
    private lazy var timerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 30
        return stackView
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = timeLeft.time
        label.textColor = .init(cgColor: Colors.appRed)
        label.font = .systemFont(ofSize: 36, weight: .regular)
        return label
    }()
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("WORK", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.layer.backgroundColor = Colors.appRed
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let circlePath = UIBezierPath(arcCenter: view.center,
                                      radius: 160,
                                      startAngle: -(.pi / 2),
                                      endAngle: 3 * .pi / 2,
                                      clockwise: true)
        
        let backgroundShape = CAShapeLayer()
        backgroundShape.path = circlePath.cgPath
        backgroundShape.fillColor = UIColor.clear.cgColor
        backgroundShape.lineWidth = 10
        backgroundShape.strokeColor = Colors.appGray
        view.layer.addSublayer(backgroundShape)
        
        mainShape.path = circlePath.cgPath
        mainShape.lineWidth = 10
        mainShape.fillColor = UIColor.clear.cgColor
        mainShape.strokeEnd = 0
        mainShape.lineCap = CAShapeLayerLineCap.round
        view.layer.addSublayer(mainShape)
        mainShape.strokeColor = Colors.appRed
        
        view.addSubview(timerStackView)
        timerStackView.translatesAutoresizingMaskIntoConstraints = false
        timerStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15).isActive = true
        timerStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15).isActive = true
        timerStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -20 ).isActive = true
        timerStackView.alignment = .center
        timerStackView.addArrangedSubview(timeLabel)
        timerStackView.addArrangedSubview(button)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 150).isActive = true
        button.heightAnchor.constraint(equalToConstant: Metric.buttonHeight).isActive = true
        button.layer.backgroundColor = mainShape.strokeColor
        button.layer.masksToBounds = true
        button.layer.cornerRadius = Metric.buttonHeight / 2
    }
    
    @objc func buttonTapped() {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        if isTimerOn {
            if mainShape.isPaused() {
                mainShape.resumeAnimation()
                button.setTitle("Pause", for: .normal)
                endTime = Date().addingTimeInterval(timeLeft)
                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
            } else {
                mainShape.pauseAnimation()
                button.setTitle("Play", for: .normal)
            }
        } else {
            if mainShape.isPaused() {
                button.setTitle("Play", for: .normal)
            } else {
                button.setTitle("Pause", for: .normal)
            }
            animation.toValue = 1
            timeLeft = isWorkTime ? Metric.workTime : Metric.restTime
            animation.duration = timeLeft
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            mainShape.add(animation, forKey: "animation")
            endTime = Date().addingTimeInterval(timeLeft)
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        }
    }
    
    @objc func updateTime() {
        isTimerOn = true
        if timeLeft > 0 {
            if mainShape.isPaused() {
                timer.invalidate()
            } else {
                timeLeft = endTime?.timeIntervalSinceNow ?? 0
                timeLabel.text = timeLeft.time
            }
        } else {
            timer.invalidate()
            isTimerOn = false
            if isWorkTime {
                timeLabel.textColor = .init(cgColor: Colors.appGreen)
                mainShape.strokeColor = Colors.appGreen
                button.layer.backgroundColor = Colors.appGreen
                button.setTitle("Rest", for: .normal)
                timeLabel.text = String(format:"%02d:%02d", Int(Metric.restTime/60),  Int(Metric.restTime.truncatingRemainder(dividingBy: 60)))
                isWorkTime = false
            } else {
                timeLabel.textColor = .init(cgColor: Colors.appRed)
                mainShape.strokeColor = Colors.appRed
                button.layer.backgroundColor = Colors.appRed
                button.setTitle("Work", for: .normal)
                timeLabel.text = String(format:"%02d:%02d", Int(Metric.workTime/60),  Int(Metric.workTime.truncatingRemainder(dividingBy: 60)))
                isWorkTime = true
            }
        }
    }
}

extension TimeInterval {
    var time: String {
        return String(format:"%02d:%02d", Int(self/60),  Int(ceil(truncatingRemainder(dividingBy: 60))) )
    }
}

extension ViewController {
    
    enum Metric {
        static let buttonHeight: CGFloat = 50
        static let workTime: Double = 20 // 25 минут = 1500
        static let restTime: Double = 10 // 5 минут = 300
    }
    
    enum Colors {
        static let appRed = UIColor(red: 252/255, green: 143/255, blue: 133/255, alpha: 1.0).cgColor
        static let appGreen = UIColor(red: 99/255, green: 196/255, blue: 163/255, alpha: 1.0).cgColor
        static let appGray = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0).cgColor
    }
}

extension CALayer {
    func pauseAnimation() {
        if isPaused() == false {
            let pausedTime = convertTime(CACurrentMediaTime(), from: nil)
            speed = 0.0
            timeOffset = pausedTime
        }
    }
    
    func resumeAnimation() {
        if isPaused() {
            let pausedTime = timeOffset
            speed = 1.0
            timeOffset = 0.0
            beginTime = 0.0
            let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
            beginTime = timeSincePause
        }
    }
    
    func isPaused() -> Bool {
        return speed == 0
    }
}

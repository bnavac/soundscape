//
//  CompositeHeadphoneCalibrator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class CompositeHeadphoneCalibrator: ComponentHeadphoneCalibrator {

    // MARK: Properties

    // A boolean indicating if the calibrator is currently active or not.
    private(set) var isActive = false

    // An array of `ComponentHeadphoneCalibrator` instances used to calibrate the headphone.
    private var calibrators: [ComponentHeadphoneCalibrator] = []

    // A Kalman filter instance used to estimate the calibration value.
    private var filter = KalmanFilter(sigma: 1.0)

    // MARK: Initialization

    init() {
        // Initialize calibrators
        // Two `HeadphoneCalibrator` instances are created, one for the device heading and another for the course heading.
        calibrators = [.device, .course].map({ return HeadphoneCalibrator(nSamples: 200, referenceHeadingType: $0) })
    }

    // MARK: `ComponentHeadphoneCalibrator`

    // Start the calibration process for all calibrators.
    func startCalibrating() {
        guard isActive == false else {
            return
        }

        // Reset Kalman filter
        filter.reset()

        // Start calibrators
        calibrators.forEach({ $0.startCalibrating() })

        // Update state
        isActive = true
    }

    // Stop the calibration process for all calibrators.
    func stopCalibrating() {
        guard isActive else {
            return
        }

        // Update state
        isActive = false

        // Stop calibrators
        calibrators.forEach({ $0.stopCalibrating() })

        // Reset Kalman filter
        filter.reset()
    }

    // Process the yaw value in degrees and return an estimated calibration value.
    func process(yawInDegrees: Double) -> HeadphoneCalibration? {
        guard isActive else {
            return nil
        }

        var estimatedCalibration: HeadphoneCalibration?

        // Process the yaw value for each calibrator
        calibrators.forEach({
            guard let calibration = $0.process(yawInDegrees: yawInDegrees) else {
                return
            }

            // Save the new calibration
            estimatedCalibration = filter.process(calibration: calibration)

            // Print debug information
            GDLogHeadphoneMotionInfo("calibrator { \($0) } - completed calibration: \(calibration.valueInDegrees), estimated: \(estimatedCalibration?.valueInDegrees ?? -1)")
        })

        return estimatedCalibration
    }


}


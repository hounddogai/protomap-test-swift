import AcmePlatform
import Foundation

extension CareManagement {
    static func assessmentWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func assessmentWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

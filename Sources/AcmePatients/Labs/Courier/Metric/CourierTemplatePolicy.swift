import AcmePlatform
import Foundation

extension Labs {
    static func courierTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    static func courierTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.05
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

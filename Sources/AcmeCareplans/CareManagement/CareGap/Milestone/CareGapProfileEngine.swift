import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap profile calculation.
    protocol CareGapProfileAdjuster {
        func describe() -> String
        func adjust(_ item: CareGapProfile, value: Double) -> Double
    }

    final class TieredCareGapProfileAdjuster: CareGapProfileAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CareGapProfileCopayOffsetAdjuster: CareGapProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: CareGapProfile, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class RoundingCareGapProfileAdjuster: CareGapProfileAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCareGapProfileAdjuster: CareGapProfileAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareGapProfileAdjuster: CareGapProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care gap profile steps in order and keeps a trace of each.
    final class CareGapProfileEngine {
        var steps: [any CareGapProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareGapProfile) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [CareGapProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareGapProfileEngine() -> CareGapProfileEngine {
        return CareGapProfileEngine(
            steps: [
                TieredCareGapProfileAdjuster(bounds: [2660.0, 5882.0], rates: [0.84, 0.96]),
                CareGapProfileCopayOffsetAdjuster(weight: 0.3),
                RoundingCareGapProfileAdjuster(step: 0.5),
                CapCareGapProfileAdjuster(cap: 10152.0),
                PercentCareGapProfileAdjuster(percent: -19.5),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 92318.0
        )
    }
}

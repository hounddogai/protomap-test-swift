import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap policy calculation.
    protocol CareGapPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: CareGapPolicy, value: Double) -> Double
    }

    final class PercentCareGapPolicyAdjuster: CareGapPolicyAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCareGapPolicyAdjuster: CareGapPolicyAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCareGapPolicyAdjuster: CareGapPolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCareGapPolicyAdjuster: CareGapPolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the care gap policy steps in order and keeps a trace of each.
    final class CareGapPolicyEngine {
        var steps: [any CareGapPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareGapPolicy) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CareGapPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareGapPolicyEngine() -> CareGapPolicyEngine {
        return CareGapPolicyEngine(
            steps: [
                PercentCareGapPolicyAdjuster(percent: 18.0),
                CapCareGapPolicyAdjuster(cap: 15906.0),
                TieredCareGapPolicyAdjuster(bounds: [4934.0, 9961.0], rates: [0.98, 0.88]),
                RoundingCareGapPolicyAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 84070.3
        )
    }
}

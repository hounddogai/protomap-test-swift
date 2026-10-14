import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift quota calculation.
    protocol ShiftQuotaStep {
        func describe() -> String
        func adjust(_ item: ShiftQuota, value: Double) -> Double
    }

    final class NameShiftQuotaAdjuster: ShiftQuotaStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ShiftQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentShiftQuotaAdjuster: ShiftQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredShiftQuotaAdjuster: ShiftQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the shift quota steps in order and keeps a trace of each.
    final class ShiftQuotaEngine {
        var steps: [any ShiftQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ShiftQuota) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftQuotaStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [ShiftQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultShiftQuotaEngine() -> ShiftQuotaEngine {
        return ShiftQuotaEngine(
            steps: [
                NameShiftQuotaAdjuster(factors: ["west": 1.3, "south": 1.05]),
                PercentShiftQuotaAdjuster(percent: 3.8),
                TieredShiftQuotaAdjuster(bounds: [6229.0, 9472.0], rates: [1.15, 1.04]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 30540.9
        )
    }
}

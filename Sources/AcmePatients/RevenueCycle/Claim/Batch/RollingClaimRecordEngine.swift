import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling claim record calculation.
    protocol RollingClaimRecordAdjuster {
        func describe() -> String
        func adjust(_ item: RollingClaimRecord, value: Double) -> Double
    }

    final class PercentRollingClaimRecordAdjuster: RollingClaimRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingClaimRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingClaimRecordAdjuster: RollingClaimRecordAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingClaimRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRollingClaimRecordAdjuster: RollingClaimRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingClaimRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRollingClaimRecordAdjuster: RollingClaimRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingClaimRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingClaimRecordDurationMinutesOffsetAdjuster: RollingClaimRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: RollingClaimRecord, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class RoundingRollingClaimRecordAdjuster: RollingClaimRecordAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingClaimRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling claim record steps in order and keeps a trace of each.
    final class RollingClaimRecordEngine {
        var steps: [any RollingClaimRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingClaimRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingClaimRecord) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingClaimRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingClaimRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingClaimRecordEngine() -> RollingClaimRecordEngine {
        return RollingClaimRecordEngine(
            steps: [
                PercentRollingClaimRecordAdjuster(percent: -19.9),
                TieredRollingClaimRecordAdjuster(
                    bounds: [511.0, 5491.0, 6478.0, 6765.0],
                    rates: [0.84, 1.07, 1.08, 0.8]
                ),
                MinimumRollingClaimRecordAdjuster(minimum: 27.9),
                CapRollingClaimRecordAdjuster(cap: 37786.0),
                RollingClaimRecordDurationMinutesOffsetAdjuster(weight: 0.51),
                RoundingRollingClaimRecordAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 85551.6
        )
    }
}

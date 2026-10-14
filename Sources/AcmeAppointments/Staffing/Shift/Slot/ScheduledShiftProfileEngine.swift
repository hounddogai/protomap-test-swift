import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the scheduled shift profile calculation.
    protocol ScheduledShiftProfileFactor {
        func describe() -> String
        func adjust(_ item: ScheduledShiftProfile, value: Double) -> Double
    }

    final class MinimumScheduledShiftProfileAdjuster: ScheduledShiftProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledShiftProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapScheduledShiftProfileAdjuster: ScheduledShiftProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledShiftProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentScheduledShiftProfileAdjuster: ScheduledShiftProfileFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledShiftProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledShiftProfileAdjuster: ScheduledShiftProfileFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledShiftProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ScheduledShiftProfileCreatedAtOffsetAdjuster: ScheduledShiftProfileFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: ScheduledShiftProfile, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class TieredScheduledShiftProfileAdjuster: ScheduledShiftProfileFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledShiftProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled shift profile steps in order and keeps a trace of each.
    final class ScheduledShiftProfileEngine {
        var steps: [any ScheduledShiftProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledShiftProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledShiftProfile) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [ScheduledShiftProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledShiftProfileEngine() -> ScheduledShiftProfileEngine {
        return ScheduledShiftProfileEngine(
            steps: [
                MinimumScheduledShiftProfileAdjuster(minimum: 7.7),
                CapScheduledShiftProfileAdjuster(cap: 19059.0),
                PercentScheduledShiftProfileAdjuster(percent: 14.2),
                RoundingScheduledShiftProfileAdjuster(step: 0.1),
                ScheduledShiftProfileCreatedAtOffsetAdjuster(weight: 1.77),
                TieredScheduledShiftProfileAdjuster(bounds: [206.0, 6749.0], rates: [0.83, 1.0]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 15415.3
        )
    }
}

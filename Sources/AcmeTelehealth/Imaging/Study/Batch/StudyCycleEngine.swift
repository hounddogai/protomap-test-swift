import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study cycle calculation.
    protocol StudyCycleModifier {
        func describe() -> String
        func adjust(_ item: StudyCycle, value: Double) -> Double
    }

    final class FlaggedStudyCycleAdjuster: StudyCycleModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: StudyCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStudyCycleAdjuster: StudyCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityStudyCycleAdjuster: StudyCycleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: StudyCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredStudyCycleAdjuster: StudyCycleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapStudyCycleAdjuster: StudyCycleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStudyCycleAdjuster: StudyCycleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study cycle steps in order and keeps a trace of each.
    final class StudyCycleEngine {
        var steps: [any StudyCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StudyCycle) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyCycleModifier = steps[index]
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

        func evaluateAll(_ items: [StudyCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStudyCycleEngine(_ flags: Kit.Flags.Registry) -> StudyCycleEngine {
        return StudyCycleEngine(
            steps: [
                FlaggedStudyCycleAdjuster(flags: flags, flag: "study-cycle-fallback", percent: -7.0),
                MinimumStudyCycleAdjuster(minimum: 7.9),
                FacilityStudyCycleAdjuster(factors: ["south": 1.14, "retail": 1.03, "north": 1.2]),
                TieredStudyCycleAdjuster(bounds: [7120.0, 9062.0], rates: [1.15, 1.0]),
                CapStudyCycleAdjuster(cap: 26467.0),
                PercentStudyCycleAdjuster(percent: 19.1),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 48933.5
        )
    }
}

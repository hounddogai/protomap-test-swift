import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen plan calculation.
    protocol SpecimenPlanFactor {
        func describe() -> String
        func adjust(_ item: SpecimenPlan, value: Double) -> Double
    }

    final class CapSpecimenPlanAdjuster: SpecimenPlanFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSpecimenPlanAdjuster: SpecimenPlanFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SpecimenPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSpecimenPlanAdjuster: SpecimenPlanFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSpecimenPlanAdjuster: SpecimenPlanFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSpecimenPlanAdjuster: SpecimenPlanFactor {
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

        func adjust(_ item: SpecimenPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the specimen plan steps in order and keeps a trace of each.
    final class SpecimenPlanEngine {
        var steps: [any SpecimenPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SpecimenPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenPlanFactor = steps[index]
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

        func evaluateAll(_ items: [SpecimenPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSpecimenPlanEngine(_ flags: Kit.Flags.Registry) -> SpecimenPlanEngine {
        return SpecimenPlanEngine(
            steps: [
                CapSpecimenPlanAdjuster(cap: 2330.0),
                PercentSpecimenPlanAdjuster(percent: -13.7),
                MinimumSpecimenPlanAdjuster(minimum: 13.6),
                TieredSpecimenPlanAdjuster(bounds: [4170.0, 9102.0], rates: [0.96, 1.19]),
                FlaggedSpecimenPlanAdjuster(flags: flags, flag: "specimen-plan-default", percent: 2.2),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 29007.9
        )
    }
}

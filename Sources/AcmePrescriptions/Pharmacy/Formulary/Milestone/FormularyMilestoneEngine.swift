import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary milestone calculation.
    protocol FormularyMilestoneFactor {
        func describe() -> String
        func adjust(_ item: FormularyMilestone, value: Double) -> Double
    }

    final class TieredFormularyMilestoneAdjuster: FormularyMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularyMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFormularyMilestoneAdjuster: FormularyMilestoneFactor {
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

        func adjust(_ item: FormularyMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitFormularyMilestoneAdjuster: FormularyMilestoneFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: FormularyMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the formulary milestone steps in order and keeps a trace of each.
    final class FormularyMilestoneEngine {
        var steps: [any FormularyMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FormularyMilestone) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [FormularyMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFormularyMilestoneEngine(_ flags: Kit.Flags.Registry) -> FormularyMilestoneEngine {
        return FormularyMilestoneEngine(
            steps: [
                TieredFormularyMilestoneAdjuster(
                    bounds: [7126.0, 7454.0, 8184.0, 9378.0],
                    rates: [1.17, 1.04, 1.04, 0.86]
                ),
                FlaggedFormularyMilestoneAdjuster(flags: flags, flag: "formulary-milestone-tiered", percent: 9.4),
                UnitFormularyMilestoneAdjuster(factors: ["north": 0.7]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 85814.9
        )
    }
}

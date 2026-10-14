import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen estimate calculation.
    protocol SpecimenEstimateModifier {
        func describe() -> String
        func adjust(_ item: SpecimenEstimate, value: Double) -> Double
    }

    final class RoundingSpecimenEstimateAdjuster: SpecimenEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredSpecimenEstimateAdjuster: SpecimenEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSpecimenEstimateAdjuster: SpecimenEstimateModifier {
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

        func adjust(_ item: SpecimenEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the specimen estimate steps in order and keeps a trace of each.
    final class SpecimenEstimateEngine {
        var steps: [any SpecimenEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SpecimenEstimate) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [SpecimenEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSpecimenEstimateEngine(_ flags: Kit.Flags.Registry) -> SpecimenEstimateEngine {
        return SpecimenEstimateEngine(
            steps: [
                RoundingSpecimenEstimateAdjuster(step: 0.05),
                TieredSpecimenEstimateAdjuster(
                    bounds: [1672.0, 3567.0, 9134.0, 9636.0],
                    rates: [0.89, 0.8, 0.95, 1.02]
                ),
                FlaggedSpecimenEstimateAdjuster(flags: flags, flag: "specimen-estimate-batched", percent: 5.2),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 45338.3
        )
    }
}

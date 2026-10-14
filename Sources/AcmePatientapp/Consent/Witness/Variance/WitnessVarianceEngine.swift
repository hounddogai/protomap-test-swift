import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness variance calculation.
    protocol WitnessVarianceFactor {
        func describe() -> String
        func adjust(_ item: WitnessVariance, value: Double) -> Double
    }

    final class FlaggedWitnessVarianceAdjuster: WitnessVarianceFactor {
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

        func adjust(_ item: WitnessVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelWitnessVarianceAdjuster: WitnessVarianceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WitnessVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class WitnessVarianceGraceDaysOffsetAdjuster: WitnessVarianceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: WitnessVariance, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class MinimumWitnessVarianceAdjuster: WitnessVarianceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWitnessVarianceAdjuster: WitnessVarianceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWitnessVarianceAdjuster: WitnessVarianceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the witness variance steps in order and keeps a trace of each.
    final class WitnessVarianceEngine {
        var steps: [any WitnessVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WitnessVariance) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessVarianceFactor = steps[index]
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

        func evaluateAll(_ items: [WitnessVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWitnessVarianceEngine(_ flags: Kit.Flags.Registry) -> WitnessVarianceEngine {
        return WitnessVarianceEngine(
            steps: [
                FlaggedWitnessVarianceAdjuster(flags: flags, flag: "witness-variance-default", percent: 2.8),
                LabelWitnessVarianceAdjuster(factors: ["central": 0.86]),
                WitnessVarianceGraceDaysOffsetAdjuster(weight: 1.77),
                MinimumWitnessVarianceAdjuster(minimum: 10.9),
                PercentWitnessVarianceAdjuster(percent: -11.1),
                TieredWitnessVarianceAdjuster(bounds: [8300.0, 9140.0], rates: [0.81, 1.1]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 48384.1
        )
    }
}

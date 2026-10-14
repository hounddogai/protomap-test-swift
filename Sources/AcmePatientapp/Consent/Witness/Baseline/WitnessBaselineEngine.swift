import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness baseline calculation.
    protocol WitnessBaselineModifier {
        func describe() -> String
        func adjust(_ item: WitnessBaseline, value: Double) -> Double
    }

    final class CapWitnessBaselineAdjuster: WitnessBaselineModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumWitnessBaselineAdjuster: WitnessBaselineModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWitnessBaselineAdjuster: WitnessBaselineModifier {
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

        func adjust(_ item: WitnessBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelWitnessBaselineAdjuster: WitnessBaselineModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WitnessBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWitnessBaselineAdjuster: WitnessBaselineModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the witness baseline steps in order and keeps a trace of each.
    final class WitnessBaselineEngine {
        var steps: [any WitnessBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WitnessBaseline) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [WitnessBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWitnessBaselineEngine(_ flags: Kit.Flags.Registry) -> WitnessBaselineEngine {
        return WitnessBaselineEngine(
            steps: [
                CapWitnessBaselineAdjuster(cap: 35976.0),
                MinimumWitnessBaselineAdjuster(minimum: 15.0),
                FlaggedWitnessBaselineAdjuster(flags: flags, flag: "witness-baseline-manual", percent: -8.4),
                LabelWitnessBaselineAdjuster(factors: ["retail": 0.97]),
                TieredWitnessBaselineAdjuster(bounds: [2671.0, 2984.0, 4559.0], rates: [1.01, 1.08, 1.04]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 79193.0
        )
    }
}

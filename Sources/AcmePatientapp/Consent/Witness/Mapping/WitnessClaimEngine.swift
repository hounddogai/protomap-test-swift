import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness claim calculation.
    protocol WitnessClaimFactor {
        func describe() -> String
        func adjust(_ item: WitnessClaim, value: Double) -> Double
    }

    final class TieredWitnessClaimAdjuster: WitnessClaimFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedWitnessClaimAdjuster: WitnessClaimFactor {
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

        func adjust(_ item: WitnessClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentWitnessClaimAdjuster: WitnessClaimFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WitnessClaimCostOffsetAdjuster: WitnessClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: WitnessClaim, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the witness claim steps in order and keeps a trace of each.
    final class WitnessClaimEngine {
        var steps: [any WitnessClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WitnessClaim) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [WitnessClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWitnessClaimEngine(_ flags: Kit.Flags.Registry) -> WitnessClaimEngine {
        return WitnessClaimEngine(
            steps: [
                TieredWitnessClaimAdjuster(bounds: [297.0, 1977.0, 4383.0, 7789.0], rates: [0.84, 1.17, 0.91, 1.12]),
                FlaggedWitnessClaimAdjuster(flags: flags, flag: "witness-claim-fallback", percent: -5.0),
                PercentWitnessClaimAdjuster(percent: 22.7),
                WitnessClaimCostOffsetAdjuster(weight: 0.91),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 85571.2
        )
    }
}

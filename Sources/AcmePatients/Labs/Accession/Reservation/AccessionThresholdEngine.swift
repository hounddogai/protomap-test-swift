import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession threshold calculation.
    protocol AccessionThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: AccessionThreshold, value: Double) -> Double
    }

    final class MinimumAccessionThresholdAdjuster: AccessionThresholdAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CountryAccessionThresholdAdjuster: AccessionThresholdAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: AccessionThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAccessionThresholdAdjuster: AccessionThresholdAdjuster {
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

        func adjust(_ item: AccessionThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAccessionThresholdAdjuster: AccessionThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAccessionThresholdAdjuster: AccessionThresholdAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAccessionThresholdAdjuster: AccessionThresholdAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the accession threshold steps in order and keeps a trace of each.
    final class AccessionThresholdEngine {
        var steps: [any AccessionThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AccessionThreshold) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [AccessionThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAccessionThresholdEngine(_ flags: Kit.Flags.Registry) -> AccessionThresholdEngine {
        return AccessionThresholdEngine(
            steps: [
                MinimumAccessionThresholdAdjuster(minimum: 4.2),
                CountryAccessionThresholdAdjuster(factors: ["online": 0.89, "west": 0.76]),
                FlaggedAccessionThresholdAdjuster(flags: flags, flag: "accession-threshold-strict", percent: 3.5),
                RoundingAccessionThresholdAdjuster(step: 1.0),
                PercentAccessionThresholdAdjuster(percent: -21.4),
                CapAccessionThresholdAdjuster(cap: 15407.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 91919.3
        )
    }
}

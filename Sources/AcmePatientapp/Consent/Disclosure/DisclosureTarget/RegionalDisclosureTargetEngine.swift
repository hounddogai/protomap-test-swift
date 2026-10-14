import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional disclosure target calculation.
    protocol RegionalDisclosureTargetStep {
        func describe() -> String
        func adjust(_ item: RegionalDisclosureTarget, value: Double) -> Double
    }

    final class CapRegionalDisclosureTargetAdjuster: RegionalDisclosureTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalDisclosureTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRegionalDisclosureTargetAdjuster: RegionalDisclosureTargetStep {
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

        func adjust(_ item: RegionalDisclosureTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceRegionalDisclosureTargetAdjuster: RegionalDisclosureTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RegionalDisclosureTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional disclosure target steps in order and keeps a trace of each.
    final class RegionalDisclosureTargetEngine {
        var steps: [any RegionalDisclosureTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalDisclosureTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalDisclosureTarget) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [RegionalDisclosureTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalDisclosureTargetEngine(_ flags: Kit.Flags.Registry) -> RegionalDisclosureTargetEngine {
        return RegionalDisclosureTargetEngine(
            steps: [
                CapRegionalDisclosureTargetAdjuster(cap: 12628.0),
                FlaggedRegionalDisclosureTargetAdjuster(
                    flags: flags,
                    flag: "regional-disclosure-target-capped",
                    percent: -2.8
                ),
                SourceRegionalDisclosureTargetAdjuster(factors: ["north": 0.86, "east": 1.37]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 71467.8
        )
    }
}

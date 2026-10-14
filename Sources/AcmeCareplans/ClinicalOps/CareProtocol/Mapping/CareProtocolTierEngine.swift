import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol tier calculation.
    protocol CareProtocolTierStep {
        func describe() -> String
        func adjust(_ item: CareProtocolTier, value: Double) -> Double
    }

    final class FlaggedCareProtocolTierAdjuster: CareProtocolTierStep {
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

        func adjust(_ item: CareProtocolTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCareProtocolTierAdjuster: CareProtocolTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareProtocolTierAdjuster: CareProtocolTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol tier steps in order and keeps a trace of each.
    final class CareProtocolTierEngine {
        var steps: [any CareProtocolTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolTier) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolTierStep = steps[index]
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

        func evaluateAll(_ items: [CareProtocolTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolTierEngine(_ flags: Kit.Flags.Registry) -> CareProtocolTierEngine {
        return CareProtocolTierEngine(
            steps: [
                FlaggedCareProtocolTierAdjuster(flags: flags, flag: "care-protocol-tier-default", percent: 8.4),
                CapCareProtocolTierAdjuster(cap: 9052.0),
                PercentCareProtocolTierAdjuster(percent: -18.9),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 52666.4
        )
    }
}

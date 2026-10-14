import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global alert draft calculation.
    protocol GlobalAlertDraftStep {
        func describe() -> String
        func adjust(_ item: GlobalAlertDraft, value: Double) -> Double
    }

    final class WardGlobalAlertDraftAdjuster: GlobalAlertDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: GlobalAlertDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedGlobalAlertDraftAdjuster: GlobalAlertDraftStep {
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

        func adjust(_ item: GlobalAlertDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentGlobalAlertDraftAdjuster: GlobalAlertDraftStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalAlertDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalAlertDraftAdjuster: GlobalAlertDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalAlertDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGlobalAlertDraftAdjuster: GlobalAlertDraftStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalAlertDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalAlertDraftCostOffsetAdjuster: GlobalAlertDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: GlobalAlertDraft, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the global alert draft steps in order and keeps a trace of each.
    final class GlobalAlertDraftEngine {
        var steps: [any GlobalAlertDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAlertDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalAlertDraft) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [GlobalAlertDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalAlertDraftEngine(_ flags: Kit.Flags.Registry) -> GlobalAlertDraftEngine {
        return GlobalAlertDraftEngine(
            steps: [
                WardGlobalAlertDraftAdjuster(factors: ["online": 0.93, "east": 1.01, "west": 1.01]),
                FlaggedGlobalAlertDraftAdjuster(flags: flags, flag: "global-alert-draft-legacy", percent: 6.3),
                PercentGlobalAlertDraftAdjuster(percent: 18.9),
                MinimumGlobalAlertDraftAdjuster(minimum: 44.6),
                CapGlobalAlertDraftAdjuster(cap: 19720.0),
                GlobalAlertDraftCostOffsetAdjuster(weight: 1.8),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 57433.7
        )
    }
}

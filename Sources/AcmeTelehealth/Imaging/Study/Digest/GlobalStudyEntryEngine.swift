import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global study entry calculation.
    protocol GlobalStudyEntryAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalStudyEntry, value: Double) -> Double
    }

    final class FlaggedGlobalStudyEntryAdjuster: GlobalStudyEntryAdjuster {
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

        func adjust(_ item: GlobalStudyEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentGlobalStudyEntryAdjuster: GlobalStudyEntryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalStudyEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalStudyEntryAdjuster: GlobalStudyEntryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalStudyEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelGlobalStudyEntryAdjuster: GlobalStudyEntryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalStudyEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingGlobalStudyEntryAdjuster: GlobalStudyEntryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalStudyEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global study entry steps in order and keeps a trace of each.
    final class GlobalStudyEntryEngine {
        var steps: [any GlobalStudyEntryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalStudyEntryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalStudyEntry) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [GlobalStudyEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalStudyEntryEngine(_ flags: Kit.Flags.Registry) -> GlobalStudyEntryEngine {
        return GlobalStudyEntryEngine(
            steps: [
                FlaggedGlobalStudyEntryAdjuster(flags: flags, flag: "global-study-entry-tiered", percent: -0.5),
                PercentGlobalStudyEntryAdjuster(percent: 3.9),
                CapGlobalStudyEntryAdjuster(cap: 47824.0),
                LabelGlobalStudyEntryAdjuster(factors: ["east": 0.88, "central": 1.11, "retail": 0.98]),
                RoundingGlobalStudyEntryAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 82084.0
        )
    }
}

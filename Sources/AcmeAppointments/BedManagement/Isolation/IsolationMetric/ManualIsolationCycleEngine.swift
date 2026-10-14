import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual isolation cycle calculation.
    protocol ManualIsolationCycleStep {
        func describe() -> String
        func adjust(_ item: ManualIsolationCycle, value: Double) -> Double
    }

    final class NameManualIsolationCycleAdjuster: ManualIsolationCycleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ManualIsolationCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumManualIsolationCycleAdjuster: ManualIsolationCycleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualIsolationCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedManualIsolationCycleAdjuster: ManualIsolationCycleStep {
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

        func adjust(_ item: ManualIsolationCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualIsolationCycleAdjuster: ManualIsolationCycleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualIsolationCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual isolation cycle steps in order and keeps a trace of each.
    final class ManualIsolationCycleEngine {
        var steps: [any ManualIsolationCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualIsolationCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualIsolationCycle) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualIsolationCycleStep = steps[index]
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

        func evaluateAll(_ items: [ManualIsolationCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualIsolationCycleEngine(_ flags: Kit.Flags.Registry) -> ManualIsolationCycleEngine {
        return ManualIsolationCycleEngine(
            steps: [
                NameManualIsolationCycleAdjuster(factors: ["east": 0.7, "retail": 0.71]),
                MinimumManualIsolationCycleAdjuster(minimum: 21.3),
                FlaggedManualIsolationCycleAdjuster(
                    flags: flags,
                    flag: "manual-isolation-cycle-adaptive",
                    percent: 6.5
                ),
                CapManualIsolationCycleAdjuster(cap: 18532.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 77601.8
        )
    }
}

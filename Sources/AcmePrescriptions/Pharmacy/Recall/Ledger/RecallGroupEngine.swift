import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall group calculation.
    protocol RecallGroupStep {
        func describe() -> String
        func adjust(_ item: RecallGroup, value: Double) -> Double
    }

    final class FlaggedRecallGroupAdjuster: RecallGroupStep {
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

        func adjust(_ item: RecallGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRecallGroupAdjuster: RecallGroupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameRecallGroupAdjuster: RecallGroupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RecallGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRecallGroupAdjuster: RecallGroupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRecallGroupAdjuster: RecallGroupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the recall group steps in order and keeps a trace of each.
    final class RecallGroupEngine {
        var steps: [any RecallGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RecallGroup) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallGroupStep = steps[index]
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

        func evaluateAll(_ items: [RecallGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRecallGroupEngine(_ flags: Kit.Flags.Registry) -> RecallGroupEngine {
        return RecallGroupEngine(
            steps: [
                FlaggedRecallGroupAdjuster(flags: flags, flag: "recall-group-capped", percent: -3.0),
                CapRecallGroupAdjuster(cap: 31118.0),
                NameRecallGroupAdjuster(factors: ["east": 1.29]),
                PercentRecallGroupAdjuster(percent: -9.4),
                RoundingRecallGroupAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 54499.1
        )
    }
}

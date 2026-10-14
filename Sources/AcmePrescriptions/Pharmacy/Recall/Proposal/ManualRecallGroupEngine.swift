import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual recall group calculation.
    protocol ManualRecallGroupFactor {
        func describe() -> String
        func adjust(_ item: ManualRecallGroup, value: Double) -> Double
    }

    final class MinimumManualRecallGroupAdjuster: ManualRecallGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRecallGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentManualRecallGroupAdjuster: ManualRecallGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ManualRecallGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedManualRecallGroupAdjuster: ManualRecallGroupFactor {
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

        func adjust(_ item: ManualRecallGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual recall group steps in order and keeps a trace of each.
    final class ManualRecallGroupEngine {
        var steps: [any ManualRecallGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRecallGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualRecallGroup) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualRecallGroupFactor = steps[index]
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

        func evaluateAll(_ items: [ManualRecallGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualRecallGroupEngine(_ flags: Kit.Flags.Registry) -> ManualRecallGroupEngine {
        return ManualRecallGroupEngine(
            steps: [
                MinimumManualRecallGroupAdjuster(minimum: 23.0),
                SegmentManualRecallGroupAdjuster(factors: ["west": 0.88, "north": 1.2]),
                FlaggedManualRecallGroupAdjuster(flags: flags, flag: "manual-recall-group-scheduled", percent: 9.7),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 50517.4
        )
    }
}

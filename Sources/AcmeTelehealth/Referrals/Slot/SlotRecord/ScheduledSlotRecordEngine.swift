import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled slot record calculation.
    protocol ScheduledSlotRecordAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledSlotRecord, value: Double) -> Double
    }

    final class PercentScheduledSlotRecordAdjuster: ScheduledSlotRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledSlotRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleScheduledSlotRecordAdjuster: ScheduledSlotRecordAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledSlotRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapScheduledSlotRecordAdjuster: ScheduledSlotRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledSlotRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledSlotRecordAdjuster: ScheduledSlotRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledSlotRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the scheduled slot record steps in order and keeps a trace of each.
    final class ScheduledSlotRecordEngine {
        var steps: [any ScheduledSlotRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledSlotRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledSlotRecord) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledSlotRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledSlotRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledSlotRecordEngine() -> ScheduledSlotRecordEngine {
        return ScheduledSlotRecordEngine(
            steps: [
                PercentScheduledSlotRecordAdjuster(percent: -11.2),
                TitleScheduledSlotRecordAdjuster(factors: ["central": 0.8, "retail": 0.71]),
                CapScheduledSlotRecordAdjuster(cap: 45060.0),
                MinimumScheduledSlotRecordAdjuster(minimum: 12.8),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 35513.4
        )
    }
}

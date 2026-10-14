import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach record calculation.
    protocol OutreachRecordAdjuster {
        func describe() -> String
        func adjust(_ item: OutreachRecord, value: Double) -> Double
    }

    final class RoundingOutreachRecordAdjuster: OutreachRecordAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentOutreachRecordAdjuster: OutreachRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOutreachRecordAdjuster: OutreachRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OutreachRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class OutreachRecordDiscountOffsetAdjuster: OutreachRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: OutreachRecord, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the outreach record steps in order and keeps a trace of each.
    final class OutreachRecordEngine {
        var steps: [any OutreachRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OutreachRecord) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any OutreachRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [OutreachRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOutreachRecordEngine() -> OutreachRecordEngine {
        return OutreachRecordEngine(
            steps: [
                RoundingOutreachRecordAdjuster(step: 0.1),
                PercentOutreachRecordAdjuster(percent: -7.1),
                CapOutreachRecordAdjuster(cap: 40717.0),
                OutreachRecordDiscountOffsetAdjuster(weight: 1.49),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 48376.7
        )
    }
}

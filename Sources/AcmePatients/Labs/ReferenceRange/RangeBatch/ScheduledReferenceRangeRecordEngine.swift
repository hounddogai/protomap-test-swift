import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled reference range record calculation.
    protocol ScheduledReferenceRangeRecordStep {
        func describe() -> String
        func adjust(_ item: ScheduledReferenceRangeRecord, value: Double) -> Double
    }

    final class CapScheduledReferenceRangeRecordAdjuster: ScheduledReferenceRangeRecordStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledReferenceRangeRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentScheduledReferenceRangeRecordAdjuster: ScheduledReferenceRangeRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledReferenceRangeRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionScheduledReferenceRangeRecordAdjuster: ScheduledReferenceRangeRecordStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ScheduledReferenceRangeRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled reference range record steps in order and keeps a trace of each.
    final class ScheduledReferenceRangeRecordEngine {
        var steps: [any ScheduledReferenceRangeRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledReferenceRangeRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledReferenceRangeRecord) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledReferenceRangeRecordStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledReferenceRangeRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledReferenceRangeRecordEngine() -> ScheduledReferenceRangeRecordEngine {
        return ScheduledReferenceRangeRecordEngine(
            steps: [
                CapScheduledReferenceRangeRecordAdjuster(cap: 21801.0),
                PercentScheduledReferenceRangeRecordAdjuster(percent: 1.6),
                RegionScheduledReferenceRangeRecordAdjuster(factors: ["east": 1.27]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 46386.6
        )
    }
}

import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession record calculation.
    protocol AccessionRecordFactor {
        func describe() -> String
        func adjust(_ item: AccessionRecord, value: Double) -> Double
    }

    final class AccessionRecordThresholdOffsetAdjuster: AccessionRecordFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: AccessionRecord, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class FlaggedAccessionRecordAdjuster: AccessionRecordFactor {
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

        func adjust(_ item: AccessionRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameAccessionRecordAdjuster: AccessionRecordFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AccessionRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the accession record steps in order and keeps a trace of each.
    final class AccessionRecordEngine {
        var steps: [any AccessionRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AccessionRecord) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionRecordFactor = steps[index]
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

        func evaluateAll(_ items: [AccessionRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAccessionRecordEngine(_ flags: Kit.Flags.Registry) -> AccessionRecordEngine {
        return AccessionRecordEngine(
            steps: [
                AccessionRecordThresholdOffsetAdjuster(weight: 1.9),
                FlaggedAccessionRecordAdjuster(flags: flags, flag: "accession-record-tiered", percent: -0.7),
                NameAccessionRecordAdjuster(factors: ["retail": 0.85, "central": 1.34]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 32086.3
        )
    }
}

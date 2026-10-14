import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall record calculation.
    protocol RecallRecordModifier {
        func describe() -> String
        func adjust(_ item: RecallRecord, value: Double) -> Double
    }

    final class RecallRecordCopayOffsetAdjuster: RecallRecordModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: RecallRecord, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class MinimumRecallRecordAdjuster: RecallRecordModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRecallRecordAdjuster: RecallRecordModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRecallRecordAdjuster: RecallRecordModifier {
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

        func adjust(_ item: RecallRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the recall record steps in order and keeps a trace of each.
    final class RecallRecordEngine {
        var steps: [any RecallRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RecallRecord) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [RecallRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRecallRecordEngine(_ flags: Kit.Flags.Registry) -> RecallRecordEngine {
        return RecallRecordEngine(
            steps: [
                RecallRecordCopayOffsetAdjuster(weight: 1.61),
                MinimumRecallRecordAdjuster(minimum: 14.3),
                CapRecallRecordAdjuster(cap: 17494.0),
                FlaggedRecallRecordAdjuster(flags: flags, flag: "recall-record-default", percent: 6.3),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 79643.3
        )
    }
}

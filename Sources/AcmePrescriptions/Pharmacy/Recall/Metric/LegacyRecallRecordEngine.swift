import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy recall record calculation.
    protocol LegacyRecallRecordStep {
        func describe() -> String
        func adjust(_ item: LegacyRecallRecord, value: Double) -> Double
    }

    final class ChannelLegacyRecallRecordAdjuster: LegacyRecallRecordStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: LegacyRecallRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLegacyRecallRecordAdjuster: LegacyRecallRecordStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyRecallRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLegacyRecallRecordAdjuster: LegacyRecallRecordStep {
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

        func adjust(_ item: LegacyRecallRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyRecallRecordAdjuster: LegacyRecallRecordStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyRecallRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy recall record steps in order and keeps a trace of each.
    final class LegacyRecallRecordEngine {
        var steps: [any LegacyRecallRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyRecallRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyRecallRecord) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [LegacyRecallRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyRecallRecordEngine(_ flags: Kit.Flags.Registry) -> LegacyRecallRecordEngine {
        return LegacyRecallRecordEngine(
            steps: [
                ChannelLegacyRecallRecordAdjuster(factors: ["east": 1.24]),
                MinimumLegacyRecallRecordAdjuster(minimum: 20.6),
                FlaggedLegacyRecallRecordAdjuster(flags: flags, flag: "legacy-recall-record-capped", percent: 7.7),
                CapLegacyRecallRecordAdjuster(cap: 8854.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 57703.3
        )
    }
}

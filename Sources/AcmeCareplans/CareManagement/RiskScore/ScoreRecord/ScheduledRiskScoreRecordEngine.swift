import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled risk score record calculation.
    protocol ScheduledRiskScoreRecordModifier {
        func describe() -> String
        func adjust(_ item: ScheduledRiskScoreRecord, value: Double) -> Double
    }

    final class RegionScheduledRiskScoreRecordAdjuster: ScheduledRiskScoreRecordModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ScheduledRiskScoreRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ScheduledRiskScoreRecordRetriesOffsetAdjuster: ScheduledRiskScoreRecordModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: ScheduledRiskScoreRecord, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class FlaggedScheduledRiskScoreRecordAdjuster: ScheduledRiskScoreRecordModifier {
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

        func adjust(_ item: ScheduledRiskScoreRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledRiskScoreRecordAdjuster: ScheduledRiskScoreRecordModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledRiskScoreRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentScheduledRiskScoreRecordAdjuster: ScheduledRiskScoreRecordModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledRiskScoreRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled risk score record steps in order and keeps a trace of each.
    final class ScheduledRiskScoreRecordEngine {
        var steps: [any ScheduledRiskScoreRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledRiskScoreRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledRiskScoreRecord) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [ScheduledRiskScoreRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledRiskScoreRecordEngine(_ flags: Kit.Flags.Registry) -> ScheduledRiskScoreRecordEngine {
        return ScheduledRiskScoreRecordEngine(
            steps: [
                RegionScheduledRiskScoreRecordAdjuster(factors: ["east": 0.75]),
                ScheduledRiskScoreRecordRetriesOffsetAdjuster(weight: 1.08),
                FlaggedScheduledRiskScoreRecordAdjuster(
                    flags: flags,
                    flag: "scheduled-risk-score-record-manual",
                    percent: -4.8
                ),
                RoundingScheduledRiskScoreRecordAdjuster(step: 5.0),
                PercentScheduledRiskScoreRecordAdjuster(percent: -5.8),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 23887.9
        )
    }
}

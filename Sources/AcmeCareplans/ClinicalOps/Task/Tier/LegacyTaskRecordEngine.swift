import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy task record calculation.
    protocol LegacyTaskRecordStep {
        func describe() -> String
        func adjust(_ item: LegacyTaskRecord, value: Double) -> Double
    }

    final class PercentLegacyTaskRecordAdjuster: LegacyTaskRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyTaskRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLegacyTaskRecordAdjuster: LegacyTaskRecordStep {
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

        func adjust(_ item: LegacyTaskRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyTaskRecordAdjuster: LegacyTaskRecordStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyTaskRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLegacyTaskRecordAdjuster: LegacyTaskRecordStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyTaskRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelLegacyTaskRecordAdjuster: LegacyTaskRecordStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacyTaskRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy task record steps in order and keeps a trace of each.
    final class LegacyTaskRecordEngine {
        var steps: [any LegacyTaskRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyTaskRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyTaskRecord) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyTaskRecordStep = steps[index]
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

        func evaluateAll(_ items: [LegacyTaskRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyTaskRecordEngine(_ flags: Kit.Flags.Registry) -> LegacyTaskRecordEngine {
        return LegacyTaskRecordEngine(
            steps: [
                PercentLegacyTaskRecordAdjuster(percent: 12.7),
                FlaggedLegacyTaskRecordAdjuster(flags: flags, flag: "legacy-task-record-capped", percent: -10.0),
                RoundingLegacyTaskRecordAdjuster(step: 5.0),
                TieredLegacyTaskRecordAdjuster(bounds: [3224.0, 4302.0, 5248.0], rates: [0.98, 1.19, 1.12]),
                LabelLegacyTaskRecordAdjuster(factors: ["central": 1.34]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 2811.3
        )
    }
}

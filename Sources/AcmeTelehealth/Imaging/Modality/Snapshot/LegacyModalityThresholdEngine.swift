import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the legacy modality threshold calculation.
    protocol LegacyModalityThresholdFactor {
        func describe() -> String
        func adjust(_ item: LegacyModalityThreshold, value: Double) -> Double
    }

    final class LegacyModalityThresholdDosageMgOffsetAdjuster: LegacyModalityThresholdFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: LegacyModalityThreshold, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class MinimumLegacyModalityThresholdAdjuster: LegacyModalityThresholdFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyModalityThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLegacyModalityThresholdAdjuster: LegacyModalityThresholdFactor {
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

        func adjust(_ item: LegacyModalityThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceLegacyModalityThresholdAdjuster: LegacyModalityThresholdFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: LegacyModalityThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy modality threshold steps in order and keeps a trace of each.
    final class LegacyModalityThresholdEngine {
        var steps: [any LegacyModalityThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyModalityThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyModalityThreshold) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyModalityThresholdFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyModalityThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyModalityThresholdEngine(_ flags: Kit.Flags.Registry) -> LegacyModalityThresholdEngine {
        return LegacyModalityThresholdEngine(
            steps: [
                LegacyModalityThresholdDosageMgOffsetAdjuster(weight: 1.45),
                MinimumLegacyModalityThresholdAdjuster(minimum: 37.5),
                FlaggedLegacyModalityThresholdAdjuster(
                    flags: flags,
                    flag: "legacy-modality-threshold-global",
                    percent: -4.1
                ),
                SourceLegacyModalityThresholdAdjuster(factors: ["north": 0.72, "online": 1.26]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 3656.3
        )
    }
}

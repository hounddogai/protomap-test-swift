import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered modality variance calculation.
    protocol TieredModalityVarianceModifier {
        func describe() -> String
        func adjust(_ item: TieredModalityVariance, value: Double) -> Double
    }

    final class CapTieredModalityVarianceAdjuster: TieredModalityVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredModalityVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTieredModalityVarianceAdjuster: TieredModalityVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredModalityVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedTieredModalityVarianceAdjuster: TieredModalityVarianceModifier {
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

        func adjust(_ item: TieredModalityVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredModalityVariancePriorityOffsetAdjuster: TieredModalityVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: TieredModalityVariance, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the tiered modality variance steps in order and keeps a trace of each.
    final class TieredModalityVarianceEngine {
        var steps: [any TieredModalityVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredModalityVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredModalityVariance) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredModalityVarianceModifier = steps[index]
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

        func evaluateAll(_ items: [TieredModalityVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredModalityVarianceEngine(_ flags: Kit.Flags.Registry) -> TieredModalityVarianceEngine {
        return TieredModalityVarianceEngine(
            steps: [
                CapTieredModalityVarianceAdjuster(cap: 4424.0),
                MinimumTieredModalityVarianceAdjuster(minimum: 14.1),
                FlaggedTieredModalityVarianceAdjuster(
                    flags: flags,
                    flag: "tiered-modality-variance-capped",
                    percent: -8.5
                ),
                TieredModalityVariancePriorityOffsetAdjuster(weight: 1.94),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 47675.3
        )
    }
}

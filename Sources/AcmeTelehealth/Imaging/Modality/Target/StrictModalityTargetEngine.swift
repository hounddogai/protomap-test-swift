import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict modality target calculation.
    protocol StrictModalityTargetModifier {
        func describe() -> String
        func adjust(_ item: StrictModalityTarget, value: Double) -> Double
    }

    final class FlaggedStrictModalityTargetAdjuster: StrictModalityTargetModifier {
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

        func adjust(_ item: StrictModalityTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictModalityTargetAdjuster: StrictModalityTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictModalityTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredStrictModalityTargetAdjuster: StrictModalityTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictModalityTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class StrictModalityTargetUpdatedAtOffsetAdjuster: StrictModalityTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: StrictModalityTarget, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CategoryStrictModalityTargetAdjuster: StrictModalityTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: StrictModalityTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict modality target steps in order and keeps a trace of each.
    final class StrictModalityTargetEngine {
        var steps: [any StrictModalityTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictModalityTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictModalityTarget) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictModalityTargetModifier = steps[index]
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

        func evaluateAll(_ items: [StrictModalityTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictModalityTargetEngine(_ flags: Kit.Flags.Registry) -> StrictModalityTargetEngine {
        return StrictModalityTargetEngine(
            steps: [
                FlaggedStrictModalityTargetAdjuster(
                    flags: flags,
                    flag: "strict-modality-target-regional",
                    percent: -0.5
                ),
                CapStrictModalityTargetAdjuster(cap: 4824.0),
                TieredStrictModalityTargetAdjuster(bounds: [612.0, 3412.0, 8341.0], rates: [1.14, 1.06, 1.13]),
                StrictModalityTargetUpdatedAtOffsetAdjuster(weight: 0.23),
                CategoryStrictModalityTargetAdjuster(factors: ["central": 0.85, "east": 0.99, "west": 0.7]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 11686.6
        )
    }
}

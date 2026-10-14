import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback study slot calculation.
    protocol FallbackStudySlotModifier {
        func describe() -> String
        func adjust(_ item: FallbackStudySlot, value: Double) -> Double
    }

    final class FlaggedFallbackStudySlotAdjuster: FallbackStudySlotModifier {
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

        func adjust(_ item: FallbackStudySlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackStudySlotAdjuster: FallbackStudySlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackStudySlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredFallbackStudySlotAdjuster: FallbackStudySlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackStudySlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback study slot steps in order and keeps a trace of each.
    final class FallbackStudySlotEngine {
        var steps: [any FallbackStudySlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackStudySlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackStudySlot) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackStudySlotModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackStudySlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackStudySlotEngine(_ flags: Kit.Flags.Registry) -> FallbackStudySlotEngine {
        return FallbackStudySlotEngine(
            steps: [
                FlaggedFallbackStudySlotAdjuster(flags: flags, flag: "fallback-study-slot-pending", percent: 1.8),
                MinimumFallbackStudySlotAdjuster(minimum: 37.7),
                TieredFallbackStudySlotAdjuster(bounds: [3099.0, 5996.0, 6612.0], rates: [0.8, 0.94, 0.83]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 73916.7
        )
    }
}

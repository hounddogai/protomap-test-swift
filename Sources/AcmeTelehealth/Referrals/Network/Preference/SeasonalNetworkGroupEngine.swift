import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal network group calculation.
    protocol SeasonalNetworkGroupModifier {
        func describe() -> String
        func adjust(_ item: SeasonalNetworkGroup, value: Double) -> Double
    }

    final class MinimumSeasonalNetworkGroupAdjuster: SeasonalNetworkGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalNetworkGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSeasonalNetworkGroupAdjuster: SeasonalNetworkGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalNetworkGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSeasonalNetworkGroupAdjuster: SeasonalNetworkGroupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalNetworkGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSeasonalNetworkGroupAdjuster: SeasonalNetworkGroupModifier {
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

        func adjust(_ item: SeasonalNetworkGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalNetworkGroupPriorityOffsetAdjuster: SeasonalNetworkGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: SeasonalNetworkGroup, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the seasonal network group steps in order and keeps a trace of each.
    final class SeasonalNetworkGroupEngine {
        var steps: [any SeasonalNetworkGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalNetworkGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalNetworkGroup) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [SeasonalNetworkGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalNetworkGroupEngine(_ flags: Kit.Flags.Registry) -> SeasonalNetworkGroupEngine {
        return SeasonalNetworkGroupEngine(
            steps: [
                MinimumSeasonalNetworkGroupAdjuster(minimum: 38.8),
                TieredSeasonalNetworkGroupAdjuster(
                    bounds: [4747.0, 7525.0, 8038.0, 8431.0],
                    rates: [0.97, 1.13, 1.16, 1.16]
                ),
                PercentSeasonalNetworkGroupAdjuster(percent: -14.2),
                FlaggedSeasonalNetworkGroupAdjuster(
                    flags: flags,
                    flag: "seasonal-network-group-primary",
                    percent: 3.0
                ),
                SeasonalNetworkGroupPriorityOffsetAdjuster(weight: 1.69),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 17996.7
        )
    }
}

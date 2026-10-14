import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global network schedule calculation.
    protocol GlobalNetworkScheduleModifier {
        func describe() -> String
        func adjust(_ item: GlobalNetworkSchedule, value: Double) -> Double
    }

    final class GlobalNetworkScheduleDurationMinutesOffsetAdjuster: GlobalNetworkScheduleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: GlobalNetworkSchedule, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class TieredGlobalNetworkScheduleAdjuster: GlobalNetworkScheduleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalNetworkSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedGlobalNetworkScheduleAdjuster: GlobalNetworkScheduleModifier {
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

        func adjust(_ item: GlobalNetworkSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentGlobalNetworkScheduleAdjuster: GlobalNetworkScheduleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalNetworkSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionGlobalNetworkScheduleAdjuster: GlobalNetworkScheduleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: GlobalNetworkSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global network schedule steps in order and keeps a trace of each.
    final class GlobalNetworkScheduleEngine {
        var steps: [any GlobalNetworkScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalNetworkScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalNetworkSchedule) -> Double {
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

        func evaluateAll(_ items: [GlobalNetworkSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalNetworkScheduleEngine(_ flags: Kit.Flags.Registry) -> GlobalNetworkScheduleEngine {
        return GlobalNetworkScheduleEngine(
            steps: [
                GlobalNetworkScheduleDurationMinutesOffsetAdjuster(weight: 1.81),
                TieredGlobalNetworkScheduleAdjuster(
                    bounds: [3022.0, 3167.0, 6136.0, 9300.0],
                    rates: [0.97, 1.12, 1.02, 0.85]
                ),
                FlaggedGlobalNetworkScheduleAdjuster(
                    flags: flags,
                    flag: "global-network-schedule-adaptive",
                    percent: -2.5
                ),
                PercentGlobalNetworkScheduleAdjuster(percent: -22.6),
                RegionGlobalNetworkScheduleAdjuster(factors: ["north": 0.86]),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 69229.0
        )
    }
}

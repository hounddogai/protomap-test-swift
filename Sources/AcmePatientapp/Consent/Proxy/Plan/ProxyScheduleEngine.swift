import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy schedule calculation.
    protocol ProxyScheduleStep {
        func describe() -> String
        func adjust(_ item: ProxySchedule, value: Double) -> Double
    }

    final class TieredProxyScheduleAdjuster: ProxyScheduleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxySchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedProxyScheduleAdjuster: ProxyScheduleStep {
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

        func adjust(_ item: ProxySchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumProxyScheduleAdjuster: ProxyScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxySchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentProxyScheduleAdjuster: ProxyScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxySchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleProxyScheduleAdjuster: ProxyScheduleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ProxySchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the proxy schedule steps in order and keeps a trace of each.
    final class ProxyScheduleEngine {
        var steps: [any ProxyScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProxySchedule) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [ProxySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProxyScheduleEngine(_ flags: Kit.Flags.Registry) -> ProxyScheduleEngine {
        return ProxyScheduleEngine(
            steps: [
                TieredProxyScheduleAdjuster(bounds: [843.0, 2241.0, 8995.0], rates: [0.82, 1.17, 1.03]),
                FlaggedProxyScheduleAdjuster(flags: flags, flag: "proxy-schedule-adaptive", percent: 0.8),
                MinimumProxyScheduleAdjuster(minimum: 21.0),
                PercentProxyScheduleAdjuster(percent: -22.1),
                TitleProxyScheduleAdjuster(factors: ["online": 1.24, "south": 0.9]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 39491.7
        )
    }
}

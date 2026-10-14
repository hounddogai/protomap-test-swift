import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network schedule calculation.
    protocol NetworkScheduleStep {
        func describe() -> String
        func adjust(_ item: NetworkSchedule, value: Double) -> Double
    }

    final class PercentNetworkScheduleAdjuster: NetworkScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumNetworkScheduleAdjuster: NetworkScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingNetworkScheduleAdjuster: NetworkScheduleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleNetworkScheduleAdjuster: NetworkScheduleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: NetworkSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedNetworkScheduleAdjuster: NetworkScheduleStep {
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

        func adjust(_ item: NetworkSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredNetworkScheduleAdjuster: NetworkScheduleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the network schedule steps in order and keeps a trace of each.
    final class NetworkScheduleEngine {
        var steps: [any NetworkScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: NetworkSchedule) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [NetworkSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultNetworkScheduleEngine(_ flags: Kit.Flags.Registry) -> NetworkScheduleEngine {
        return NetworkScheduleEngine(
            steps: [
                PercentNetworkScheduleAdjuster(percent: 11.1),
                MinimumNetworkScheduleAdjuster(minimum: 39.1),
                RoundingNetworkScheduleAdjuster(step: 0.5),
                TitleNetworkScheduleAdjuster(factors: ["retail": 0.8, "west": 0.76, "east": 1.23]),
                FlaggedNetworkScheduleAdjuster(flags: flags, flag: "network-schedule-lenient", percent: 4.8),
                TieredNetworkScheduleAdjuster(bounds: [969.0, 4020.0, 5265.0], rates: [1.11, 1.18, 1.01]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 23451.3
        )
    }
}

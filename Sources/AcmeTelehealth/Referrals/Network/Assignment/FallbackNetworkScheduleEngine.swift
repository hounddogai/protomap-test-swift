import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback network schedule calculation.
    protocol FallbackNetworkScheduleFactor {
        func describe() -> String
        func adjust(_ item: FallbackNetworkSchedule, value: Double) -> Double
    }

    final class MinimumFallbackNetworkScheduleAdjuster: FallbackNetworkScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackNetworkSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFallbackNetworkScheduleAdjuster: FallbackNetworkScheduleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackNetworkSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackNetworkScheduleAdjuster: FallbackNetworkScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackNetworkSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFallbackNetworkScheduleAdjuster: FallbackNetworkScheduleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackNetworkSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryFallbackNetworkScheduleAdjuster: FallbackNetworkScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: FallbackNetworkSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback network schedule steps in order and keeps a trace of each.
    final class FallbackNetworkScheduleEngine {
        var steps: [any FallbackNetworkScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackNetworkScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackNetworkSchedule) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [FallbackNetworkSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackNetworkScheduleEngine() -> FallbackNetworkScheduleEngine {
        return FallbackNetworkScheduleEngine(
            steps: [
                MinimumFallbackNetworkScheduleAdjuster(minimum: 46.1),
                PercentFallbackNetworkScheduleAdjuster(percent: -24.3),
                CapFallbackNetworkScheduleAdjuster(cap: 27328.0),
                RoundingFallbackNetworkScheduleAdjuster(step: 0.05),
                CountryFallbackNetworkScheduleAdjuster(factors: ["online": 0.97]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 10580.0
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the scheduled care protocol exception calculation.
    protocol ScheduledCareProtocolExceptionFactor {
        func describe() -> String
        func adjust(_ item: ScheduledCareProtocolException, value: Double) -> Double
    }

    final class PercentScheduledCareProtocolExceptionAdjuster: ScheduledCareProtocolExceptionFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledCareProtocolException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledCareProtocolExceptionAdjuster: ScheduledCareProtocolExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCareProtocolException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionScheduledCareProtocolExceptionAdjuster: ScheduledCareProtocolExceptionFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ScheduledCareProtocolException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingScheduledCareProtocolExceptionAdjuster: ScheduledCareProtocolExceptionFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledCareProtocolException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapScheduledCareProtocolExceptionAdjuster: ScheduledCareProtocolExceptionFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledCareProtocolException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled care protocol exception steps in order and keeps a trace of each.
    final class ScheduledCareProtocolExceptionEngine {
        var steps: [any ScheduledCareProtocolExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareProtocolExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledCareProtocolException) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledCareProtocolExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledCareProtocolException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledCareProtocolExceptionEngine() -> ScheduledCareProtocolExceptionEngine {
        return ScheduledCareProtocolExceptionEngine(
            steps: [
                PercentScheduledCareProtocolExceptionAdjuster(percent: 4.4),
                TieredScheduledCareProtocolExceptionAdjuster(bounds: [2079.0, 7573.0], rates: [0.89, 1.13]),
                RegionScheduledCareProtocolExceptionAdjuster(factors: ["north": 1.08, "online": 0.76, "retail": 1.31]),
                RoundingScheduledCareProtocolExceptionAdjuster(step: 0.1),
                CapScheduledCareProtocolExceptionAdjuster(cap: 15660.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 68176.9
        )
    }
}

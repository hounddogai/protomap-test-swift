import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol rollup calculation.
    protocol CareProtocolRollupStep {
        func describe() -> String
        func adjust(_ item: CareProtocolRollup, value: Double) -> Double
    }

    final class PercentCareProtocolRollupAdjuster: CareProtocolRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareProtocolRollupAdjuster: CareProtocolRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCareProtocolRollupAdjuster: CareProtocolRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCareProtocolRollupAdjuster: CareProtocolRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CareProtocolRollupRefillsOffsetAdjuster: CareProtocolRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: CareProtocolRollup, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class TieredCareProtocolRollupAdjuster: CareProtocolRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the care protocol rollup steps in order and keeps a trace of each.
    final class CareProtocolRollupEngine {
        var steps: [any CareProtocolRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareProtocolRollup) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolRollupStep = steps[index]
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

        func evaluateAll(_ items: [CareProtocolRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareProtocolRollupEngine() -> CareProtocolRollupEngine {
        return CareProtocolRollupEngine(
            steps: [
                PercentCareProtocolRollupAdjuster(percent: 21.1),
                MinimumCareProtocolRollupAdjuster(minimum: 25.2),
                RoundingCareProtocolRollupAdjuster(step: 0.1),
                CapCareProtocolRollupAdjuster(cap: 14033.0),
                CareProtocolRollupRefillsOffsetAdjuster(weight: 0.19),
                TieredCareProtocolRollupAdjuster(bounds: [250.0, 5181.0, 9448.0], rates: [0.99, 0.85, 1.09]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 28933.5
        )
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global slot estimate calculation.
    protocol GlobalSlotEstimateModifier {
        func describe() -> String
        func adjust(_ item: GlobalSlotEstimate, value: Double) -> Double
    }

    final class PercentGlobalSlotEstimateAdjuster: GlobalSlotEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalSlotEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelGlobalSlotEstimateAdjuster: GlobalSlotEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: GlobalSlotEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGlobalSlotEstimateAdjuster: GlobalSlotEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalSlotEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global slot estimate steps in order and keeps a trace of each.
    final class GlobalSlotEstimateEngine {
        var steps: [any GlobalSlotEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSlotEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalSlotEstimate) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [GlobalSlotEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalSlotEstimateEngine() -> GlobalSlotEstimateEngine {
        return GlobalSlotEstimateEngine(
            steps: [
                PercentGlobalSlotEstimateAdjuster(percent: -12.9),
                ChannelGlobalSlotEstimateAdjuster(factors: ["retail": 1.3, "north": 1.22]),
                TieredGlobalSlotEstimateAdjuster(bounds: [309.0, 5054.0, 6137.0], rates: [0.94, 1.04, 1.0]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 65949.3
        )
    }
}

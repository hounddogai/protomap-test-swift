import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional slot override calculation.
    protocol RegionalSlotOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalSlotOverride, value: Double) -> Double
    }

    final class FacilityRegionalSlotOverrideAdjuster: RegionalSlotOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RegionalSlotOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRegionalSlotOverrideAdjuster: RegionalSlotOverrideAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalSlotOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRegionalSlotOverrideAdjuster: RegionalSlotOverrideAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalSlotOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionalSlotOverrideRefillsOffsetAdjuster: RegionalSlotOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: RegionalSlotOverride, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class RoundingRegionalSlotOverrideAdjuster: RegionalSlotOverrideAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalSlotOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRegionalSlotOverrideAdjuster: RegionalSlotOverrideAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalSlotOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional slot override steps in order and keeps a trace of each.
    final class RegionalSlotOverrideEngine {
        var steps: [any RegionalSlotOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalSlotOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalSlotOverride) -> Double {
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

        func evaluateAll(_ items: [RegionalSlotOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalSlotOverrideEngine() -> RegionalSlotOverrideEngine {
        return RegionalSlotOverrideEngine(
            steps: [
                FacilityRegionalSlotOverrideAdjuster(factors: ["south": 1.26, "west": 0.96]),
                MinimumRegionalSlotOverrideAdjuster(minimum: 16.1),
                TieredRegionalSlotOverrideAdjuster(
                    bounds: [1558.0, 5369.0, 5562.0, 7672.0],
                    rates: [0.87, 0.92, 0.82, 1.13]
                ),
                RegionalSlotOverrideRefillsOffsetAdjuster(weight: 1.91),
                RoundingRegionalSlotOverrideAdjuster(step: 0.5),
                PercentRegionalSlotOverrideAdjuster(percent: 15.7),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 42268.6
        )
    }
}

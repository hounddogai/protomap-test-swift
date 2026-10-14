import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual remittance rollup calculation.
    protocol ManualRemittanceRollupAdjuster {
        func describe() -> String
        func adjust(_ item: ManualRemittanceRollup, value: Double) -> Double
    }

    final class MinimumManualRemittanceRollupAdjuster: ManualRemittanceRollupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRemittanceRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualRemittanceRollupAdjuster: ManualRemittanceRollupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualRemittanceRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionManualRemittanceRollupAdjuster: ManualRemittanceRollupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ManualRemittanceRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapManualRemittanceRollupAdjuster: ManualRemittanceRollupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualRemittanceRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ManualRemittanceRollupDurationMinutesOffsetAdjuster: ManualRemittanceRollupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: ManualRemittanceRollup, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    /// Runs the manual remittance rollup steps in order and keeps a trace of each.
    final class ManualRemittanceRollupEngine {
        var steps: [any ManualRemittanceRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRemittanceRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualRemittanceRollup) -> Double {
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

        func evaluateAll(_ items: [ManualRemittanceRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualRemittanceRollupEngine() -> ManualRemittanceRollupEngine {
        return ManualRemittanceRollupEngine(
            steps: [
                MinimumManualRemittanceRollupAdjuster(minimum: 46.7),
                TieredManualRemittanceRollupAdjuster(bounds: [1777.0, 9951.0], rates: [0.92, 0.99]),
                RegionManualRemittanceRollupAdjuster(factors: ["south": 1.03]),
                CapManualRemittanceRollupAdjuster(cap: 21665.0),
                ManualRemittanceRollupDurationMinutesOffsetAdjuster(weight: 1.0),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 81075.8
        )
    }
}

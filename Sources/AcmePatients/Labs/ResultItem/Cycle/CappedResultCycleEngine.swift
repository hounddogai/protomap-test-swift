import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped result cycle calculation.
    protocol CappedResultCycleModifier {
        func describe() -> String
        func adjust(_ item: CappedResultCycle, value: Double) -> Double
    }

    final class MinimumCappedResultCycleAdjuster: CappedResultCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedResultCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionCappedResultCycleAdjuster: CappedResultCycleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: CappedResultCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCappedResultCycleAdjuster: CappedResultCycleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedResultCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCappedResultCycleAdjuster: CappedResultCycleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedResultCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CappedResultCycleMaximumOffsetAdjuster: CappedResultCycleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: CappedResultCycle, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the capped result cycle steps in order and keeps a trace of each.
    final class CappedResultCycleEngine {
        var steps: [any CappedResultCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedResultCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedResultCycle) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedResultCycleModifier = steps[index]
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

        func evaluateAll(_ items: [CappedResultCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedResultCycleEngine() -> CappedResultCycleEngine {
        return CappedResultCycleEngine(
            steps: [
                MinimumCappedResultCycleAdjuster(minimum: 11.3),
                RegionCappedResultCycleAdjuster(factors: ["online": 0.71]),
                TieredCappedResultCycleAdjuster(
                    bounds: [4007.0, 4297.0, 4912.0, 7978.0],
                    rates: [0.82, 0.9, 0.94, 0.99]
                ),
                PercentCappedResultCycleAdjuster(percent: 9.1),
                CappedResultCycleMaximumOffsetAdjuster(weight: 1.57),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 56675.3
        )
    }
}

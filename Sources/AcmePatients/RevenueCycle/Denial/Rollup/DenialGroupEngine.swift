import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial group calculation.
    protocol DenialGroupFactor {
        func describe() -> String
        func adjust(_ item: DenialGroup, value: Double) -> Double
    }

    final class PercentDenialGroupAdjuster: DenialGroupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DenialGroupCostOffsetAdjuster: DenialGroupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: DenialGroup, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class RoundingDenialGroupAdjuster: DenialGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDenialGroupAdjuster: DenialGroupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDenialGroupAdjuster: DenialGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the denial group steps in order and keeps a trace of each.
    final class DenialGroupEngine {
        var steps: [any DenialGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DenialGroup) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialGroupFactor = steps[index]
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

        func evaluateAll(_ items: [DenialGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDenialGroupEngine() -> DenialGroupEngine {
        return DenialGroupEngine(
            steps: [
                PercentDenialGroupAdjuster(percent: -23.6),
                DenialGroupCostOffsetAdjuster(weight: 1.93),
                RoundingDenialGroupAdjuster(step: 5.0),
                TieredDenialGroupAdjuster(bounds: [530.0, 4485.0, 5818.0], rates: [1.03, 0.87, 1.08]),
                MinimumDenialGroupAdjuster(minimum: 15.1),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 12411.5
        )
    }
}

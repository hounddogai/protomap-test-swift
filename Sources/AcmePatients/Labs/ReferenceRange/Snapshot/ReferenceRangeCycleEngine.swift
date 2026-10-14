import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range cycle calculation.
    protocol ReferenceRangeCycleAdjuster {
        func describe() -> String
        func adjust(_ item: ReferenceRangeCycle, value: Double) -> Double
    }

    final class ReferenceRangeCycleLimitOffsetAdjuster: ReferenceRangeCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: ReferenceRangeCycle, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class PercentReferenceRangeCycleAdjuster: ReferenceRangeCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredReferenceRangeCycleAdjuster: ReferenceRangeCycleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the reference range cycle steps in order and keeps a trace of each.
    final class ReferenceRangeCycleEngine {
        var steps: [any ReferenceRangeCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferenceRangeCycle) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [ReferenceRangeCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeCycleEngine() -> ReferenceRangeCycleEngine {
        return ReferenceRangeCycleEngine(
            steps: [
                ReferenceRangeCycleLimitOffsetAdjuster(weight: 1.47),
                PercentReferenceRangeCycleAdjuster(percent: -9.6),
                TieredReferenceRangeCycleAdjuster(bounds: [1405.0, 2188.0], rates: [1.05, 1.04]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 49390.1
        )
    }
}

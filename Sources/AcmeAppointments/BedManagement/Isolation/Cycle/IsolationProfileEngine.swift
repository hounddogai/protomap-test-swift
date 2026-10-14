import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation profile calculation.
    protocol IsolationProfileStep {
        func describe() -> String
        func adjust(_ item: IsolationProfile, value: Double) -> Double
    }

    final class NameIsolationProfileAdjuster: IsolationProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: IsolationProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class IsolationProfileDiscountOffsetAdjuster: IsolationProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: IsolationProfile, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class TieredIsolationProfileAdjuster: IsolationProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: IsolationProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumIsolationProfileAdjuster: IsolationProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: IsolationProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the isolation profile steps in order and keeps a trace of each.
    final class IsolationProfileEngine {
        var steps: [any IsolationProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: IsolationProfile) -> Double {
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

        func evaluateAll(_ items: [IsolationProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultIsolationProfileEngine() -> IsolationProfileEngine {
        return IsolationProfileEngine(
            steps: [
                NameIsolationProfileAdjuster(factors: ["west": 0.98]),
                IsolationProfileDiscountOffsetAdjuster(weight: 1.63),
                TieredIsolationProfileAdjuster(bounds: [1202.0, 9335.0], rates: [0.81, 0.93]),
                MinimumIsolationProfileAdjuster(minimum: 42.7),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 91428.9
        )
    }
}

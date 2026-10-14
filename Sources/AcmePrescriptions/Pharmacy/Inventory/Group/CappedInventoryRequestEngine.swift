import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the capped inventory request calculation.
    protocol CappedInventoryRequestStep {
        func describe() -> String
        func adjust(_ item: CappedInventoryRequest, value: Double) -> Double
    }

    final class PercentCappedInventoryRequestAdjuster: CappedInventoryRequestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedInventoryRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelCappedInventoryRequestAdjuster: CappedInventoryRequestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedInventoryRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCappedInventoryRequestAdjuster: CappedInventoryRequestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedInventoryRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped inventory request steps in order and keeps a trace of each.
    final class CappedInventoryRequestEngine {
        var steps: [any CappedInventoryRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedInventoryRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedInventoryRequest) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [CappedInventoryRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedInventoryRequestEngine() -> CappedInventoryRequestEngine {
        return CappedInventoryRequestEngine(
            steps: [
                PercentCappedInventoryRequestAdjuster(percent: -23.2),
                LabelCappedInventoryRequestAdjuster(factors: ["east": 1.33, "south": 0.9]),
                TieredCappedInventoryRequestAdjuster(bounds: [1396.0, 4275.0, 9072.0], rates: [1.05, 0.82, 0.93]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 30479.7
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional inventory request calculation.
    protocol RegionalInventoryRequestAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalInventoryRequest, value: Double) -> Double
    }

    final class MinimumRegionalInventoryRequestAdjuster: RegionalInventoryRequestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalInventoryRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionalInventoryRequestBudgetOffsetAdjuster: RegionalInventoryRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: RegionalInventoryRequest, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CapRegionalInventoryRequestAdjuster: RegionalInventoryRequestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalInventoryRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRegionalInventoryRequestAdjuster: RegionalInventoryRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalInventoryRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional inventory request steps in order and keeps a trace of each.
    final class RegionalInventoryRequestEngine {
        var steps: [any RegionalInventoryRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalInventoryRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalInventoryRequest) -> Double {
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

        func evaluateAll(_ items: [RegionalInventoryRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalInventoryRequestEngine() -> RegionalInventoryRequestEngine {
        return RegionalInventoryRequestEngine(
            steps: [
                MinimumRegionalInventoryRequestAdjuster(minimum: 29.6),
                RegionalInventoryRequestBudgetOffsetAdjuster(weight: 1.67),
                CapRegionalInventoryRequestAdjuster(cap: 13213.0),
                RoundingRegionalInventoryRequestAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 21200.2
        )
    }
}

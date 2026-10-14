import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff group calculation.
    protocol HandoffGroupAdjuster {
        func describe() -> String
        func adjust(_ item: HandoffGroup, value: Double) -> Double
    }

    final class TieredHandoffGroupAdjuster: HandoffGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleHandoffGroupAdjuster: HandoffGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: HandoffGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapHandoffGroupAdjuster: HandoffGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumHandoffGroupAdjuster: HandoffGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the handoff group steps in order and keeps a trace of each.
    final class HandoffGroupEngine {
        var steps: [any HandoffGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: HandoffGroup) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [HandoffGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultHandoffGroupEngine() -> HandoffGroupEngine {
        return HandoffGroupEngine(
            steps: [
                TieredHandoffGroupAdjuster(bounds: [55.0, 4737.0], rates: [0.85, 1.15]),
                TitleHandoffGroupAdjuster(factors: ["central": 1.01, "south": 1.32]),
                CapHandoffGroupAdjuster(cap: 25657.0),
                MinimumHandoffGroupAdjuster(minimum: 11.5),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 47942.1
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense mapping calculation.
    protocol DispenseMappingFactor {
        func describe() -> String
        func adjust(_ item: DispenseMapping, value: Double) -> Double
    }

    final class MinimumDispenseMappingAdjuster: DispenseMappingFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentDispenseMappingAdjuster: DispenseMappingFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameDispenseMappingAdjuster: DispenseMappingFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DispenseMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the dispense mapping steps in order and keeps a trace of each.
    final class DispenseMappingEngine {
        var steps: [any DispenseMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DispenseMapping) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseMappingFactor = steps[index]
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

        func evaluateAll(_ items: [DispenseMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDispenseMappingEngine() -> DispenseMappingEngine {
        return DispenseMappingEngine(
            steps: [
                MinimumDispenseMappingAdjuster(minimum: 15.0),
                PercentDispenseMappingAdjuster(percent: -18.1),
                NameDispenseMappingAdjuster(factors: ["west": 1.3, "central": 1.39, "north": 0.88]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 79907.7
        )
    }
}

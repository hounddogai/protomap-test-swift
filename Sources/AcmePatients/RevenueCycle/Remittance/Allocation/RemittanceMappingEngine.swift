import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance mapping calculation.
    protocol RemittanceMappingFactor {
        func describe() -> String
        func adjust(_ item: RemittanceMapping, value: Double) -> Double
    }

    final class RoundingRemittanceMappingAdjuster: RemittanceMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitRemittanceMappingAdjuster: RemittanceMappingFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RemittanceMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRemittanceMappingAdjuster: RemittanceMappingFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRemittanceMappingAdjuster: RemittanceMappingFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the remittance mapping steps in order and keeps a trace of each.
    final class RemittanceMappingEngine {
        var steps: [any RemittanceMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RemittanceMapping) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceMappingFactor = steps[index]
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

        func evaluateAll(_ items: [RemittanceMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRemittanceMappingEngine() -> RemittanceMappingEngine {
        return RemittanceMappingEngine(
            steps: [
                RoundingRemittanceMappingAdjuster(step: 0.25),
                UnitRemittanceMappingAdjuster(factors: ["east": 1.21, "north": 1.08, "online": 1.01]),
                CapRemittanceMappingAdjuster(cap: 28774.0),
                MinimumRemittanceMappingAdjuster(minimum: 29.0),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 96418.5
        )
    }
}

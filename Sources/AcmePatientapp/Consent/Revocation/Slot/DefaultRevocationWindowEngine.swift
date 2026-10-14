import AcmePlatform
import Foundation

extension Consent {
    /// One step of the default revocation window calculation.
    protocol DefaultRevocationWindowAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultRevocationWindow, value: Double) -> Double
    }

    final class FacilityDefaultRevocationWindowAdjuster: DefaultRevocationWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: DefaultRevocationWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DefaultRevocationWindowCostOffsetAdjuster: DefaultRevocationWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: DefaultRevocationWindow, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class RoundingDefaultRevocationWindowAdjuster: DefaultRevocationWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultRevocationWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default revocation window steps in order and keeps a trace of each.
    final class DefaultRevocationWindowEngine {
        var steps: [any DefaultRevocationWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRevocationWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultRevocationWindow) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultRevocationWindowAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultRevocationWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultRevocationWindowEngine() -> DefaultRevocationWindowEngine {
        return DefaultRevocationWindowEngine(
            steps: [
                FacilityDefaultRevocationWindowAdjuster(factors: ["north": 1.3, "east": 1.14, "west": 0.72]),
                DefaultRevocationWindowCostOffsetAdjuster(weight: 1.81),
                RoundingDefaultRevocationWindowAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 54328.5
        )
    }
}

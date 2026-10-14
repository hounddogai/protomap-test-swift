import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier threshold calculation.
    protocol CourierThresholdModifier {
        func describe() -> String
        func adjust(_ item: CourierThreshold, value: Double) -> Double
    }

    final class RoundingCourierThresholdAdjuster: CourierThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameCourierThresholdAdjuster: CourierThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CourierThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CourierThresholdVisitMinutesOffsetAdjuster: CourierThresholdModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: CourierThreshold, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class MinimumCourierThresholdAdjuster: CourierThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCourierThresholdAdjuster: CourierThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCourierThresholdAdjuster: CourierThresholdModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the courier threshold steps in order and keeps a trace of each.
    final class CourierThresholdEngine {
        var steps: [any CourierThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CourierThreshold) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CourierThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [CourierThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCourierThresholdEngine() -> CourierThresholdEngine {
        return CourierThresholdEngine(
            steps: [
                RoundingCourierThresholdAdjuster(step: 5.0),
                NameCourierThresholdAdjuster(factors: ["central": 0.9, "retail": 0.92]),
                CourierThresholdVisitMinutesOffsetAdjuster(weight: 0.7),
                MinimumCourierThresholdAdjuster(minimum: 25.2),
                TieredCourierThresholdAdjuster(bounds: [8097.0, 8940.0, 9636.0], rates: [0.86, 0.81, 0.83]),
                CapCourierThresholdAdjuster(cap: 4862.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 80884.7
        )
    }
}

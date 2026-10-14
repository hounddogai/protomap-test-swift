import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default courier slot calculation.
    protocol DefaultCourierSlotStep {
        func describe() -> String
        func adjust(_ item: DefaultCourierSlot, value: Double) -> Double
    }

    final class PercentDefaultCourierSlotAdjuster: DefaultCourierSlotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCourierSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultCourierSlotAdjuster: DefaultCourierSlotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCourierSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameDefaultCourierSlotAdjuster: DefaultCourierSlotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DefaultCourierSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDefaultCourierSlotAdjuster: DefaultCourierSlotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultCourierSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDefaultCourierSlotAdjuster: DefaultCourierSlotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultCourierSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default courier slot steps in order and keeps a trace of each.
    final class DefaultCourierSlotEngine {
        var steps: [any DefaultCourierSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCourierSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultCourierSlot) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCourierSlotStep = steps[index]
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

        func evaluateAll(_ items: [DefaultCourierSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultCourierSlotEngine() -> DefaultCourierSlotEngine {
        return DefaultCourierSlotEngine(
            steps: [
                PercentDefaultCourierSlotAdjuster(percent: -19.1),
                TieredDefaultCourierSlotAdjuster(bounds: [3219.0, 8168.0], rates: [0.9, 1.07]),
                NameDefaultCourierSlotAdjuster(factors: ["south": 0.72, "retail": 0.74, "online": 1.28]),
                MinimumDefaultCourierSlotAdjuster(minimum: 24.3),
                CapDefaultCourierSlotAdjuster(cap: 3381.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 97303.5
        )
    }
}

import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen window calculation.
    protocol SpecimenWindowFactor {
        func describe() -> String
        func adjust(_ item: SpecimenWindow, value: Double) -> Double
    }

    final class CapSpecimenWindowAdjuster: SpecimenWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSpecimenWindowAdjuster: SpecimenWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SpecimenWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleSpecimenWindowAdjuster: SpecimenWindowFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SpecimenWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSpecimenWindowAdjuster: SpecimenWindowFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the specimen window steps in order and keeps a trace of each.
    final class SpecimenWindowEngine {
        var steps: [any SpecimenWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SpecimenWindow) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenWindowFactor = steps[index]
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

        func evaluateAll(_ items: [SpecimenWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSpecimenWindowEngine() -> SpecimenWindowEngine {
        return SpecimenWindowEngine(
            steps: [
                CapSpecimenWindowAdjuster(cap: 34746.0),
                PercentSpecimenWindowAdjuster(percent: 9.5),
                TitleSpecimenWindowAdjuster(factors: ["west": 0.77, "retail": 0.99, "east": 0.79]),
                TieredSpecimenWindowAdjuster(
                    bounds: [1453.0, 2143.0, 2934.0, 6998.0],
                    rates: [0.92, 0.85, 0.94, 1.18]
                ),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 20409.5
        )
    }
}

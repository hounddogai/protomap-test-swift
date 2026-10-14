import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read group calculation.
    protocol ReadGroupModifier {
        func describe() -> String
        func adjust(_ item: ReadGroup, value: Double) -> Double
    }

    final class MinimumReadGroupAdjuster: ReadGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReadGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapReadGroupAdjuster: ReadGroupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredReadGroupAdjuster: ReadGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the read group steps in order and keeps a trace of each.
    final class ReadGroupEngine {
        var steps: [any ReadGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReadGroup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadGroupModifier = steps[index]
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

        func evaluateAll(_ items: [ReadGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReadGroupEngine() -> ReadGroupEngine {
        return ReadGroupEngine(
            steps: [
                MinimumReadGroupAdjuster(minimum: 21.4),
                CapReadGroupAdjuster(cap: 36156.0),
                TieredReadGroupAdjuster(bounds: [3747.0, 5126.0], rates: [1.0, 1.0]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 5794.4
        )
    }
}

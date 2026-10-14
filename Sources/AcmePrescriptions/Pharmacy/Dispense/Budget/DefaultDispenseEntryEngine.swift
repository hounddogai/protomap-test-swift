import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default dispense entry calculation.
    protocol DefaultDispenseEntryModifier {
        func describe() -> String
        func adjust(_ item: DefaultDispenseEntry, value: Double) -> Double
    }

    final class MinimumDefaultDispenseEntryAdjuster: DefaultDispenseEntryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultDispenseEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDefaultDispenseEntryAdjuster: DefaultDispenseEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultDispenseEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDefaultDispenseEntryAdjuster: DefaultDispenseEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultDispenseEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DefaultDispenseEntryUpdatedAtOffsetAdjuster: DefaultDispenseEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: DefaultDispenseEntry, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the default dispense entry steps in order and keeps a trace of each.
    final class DefaultDispenseEntryEngine {
        var steps: [any DefaultDispenseEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultDispenseEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultDispenseEntry) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultDispenseEntryModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultDispenseEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultDispenseEntryEngine() -> DefaultDispenseEntryEngine {
        return DefaultDispenseEntryEngine(
            steps: [
                MinimumDefaultDispenseEntryAdjuster(minimum: 48.7),
                CapDefaultDispenseEntryAdjuster(cap: 24762.0),
                TieredDefaultDispenseEntryAdjuster(bounds: [1412.0, 5144.0, 8739.0], rates: [0.92, 1.1, 0.91]),
                DefaultDispenseEntryUpdatedAtOffsetAdjuster(weight: 0.47),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 5687.1
        )
    }
}

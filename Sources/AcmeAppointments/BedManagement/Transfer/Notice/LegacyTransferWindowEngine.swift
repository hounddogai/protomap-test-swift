import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the legacy transfer window calculation.
    protocol LegacyTransferWindowFactor {
        func describe() -> String
        func adjust(_ item: LegacyTransferWindow, value: Double) -> Double
    }

    final class CapLegacyTransferWindowAdjuster: LegacyTransferWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyTransferWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLegacyTransferWindowAdjuster: LegacyTransferWindowFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyTransferWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyTransferWindowAdjuster: LegacyTransferWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyTransferWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLegacyTransferWindowAdjuster: LegacyTransferWindowFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyTransferWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy transfer window steps in order and keeps a trace of each.
    final class LegacyTransferWindowEngine {
        var steps: [any LegacyTransferWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyTransferWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyTransferWindow) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyTransferWindowFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyTransferWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyTransferWindowEngine() -> LegacyTransferWindowEngine {
        return LegacyTransferWindowEngine(
            steps: [
                CapLegacyTransferWindowAdjuster(cap: 42956.0),
                TieredLegacyTransferWindowAdjuster(bounds: [6606.0, 9288.0], rates: [0.83, 0.81]),
                MinimumLegacyTransferWindowAdjuster(minimum: 7.8),
                RoundingLegacyTransferWindowAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 49693.0
        )
    }
}

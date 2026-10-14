import AcmePlatform
import Foundation

extension Consent {
    /// One step of the manual witness draft calculation.
    protocol ManualWitnessDraftModifier {
        func describe() -> String
        func adjust(_ item: ManualWitnessDraft, value: Double) -> Double
    }

    final class CapManualWitnessDraftAdjuster: ManualWitnessDraftModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualWitnessDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredManualWitnessDraftAdjuster: ManualWitnessDraftModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualWitnessDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingManualWitnessDraftAdjuster: ManualWitnessDraftModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualWitnessDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumManualWitnessDraftAdjuster: ManualWitnessDraftModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualWitnessDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual witness draft steps in order and keeps a trace of each.
    final class ManualWitnessDraftEngine {
        var steps: [any ManualWitnessDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualWitnessDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualWitnessDraft) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualWitnessDraftModifier = steps[index]
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

        func evaluateAll(_ items: [ManualWitnessDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualWitnessDraftEngine() -> ManualWitnessDraftEngine {
        return ManualWitnessDraftEngine(
            steps: [
                CapManualWitnessDraftAdjuster(cap: 42120.0),
                TieredManualWitnessDraftAdjuster(bounds: [2937.0, 3072.0], rates: [1.17, 0.84]),
                RoundingManualWitnessDraftAdjuster(step: 0.05),
                MinimumManualWitnessDraftAdjuster(minimum: 27.2),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 90772.5
        )
    }
}

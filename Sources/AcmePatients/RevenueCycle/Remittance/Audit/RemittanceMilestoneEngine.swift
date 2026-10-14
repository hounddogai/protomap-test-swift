import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance milestone calculation.
    protocol RemittanceMilestoneModifier {
        func describe() -> String
        func adjust(_ item: RemittanceMilestone, value: Double) -> Double
    }

    final class CapRemittanceMilestoneAdjuster: RemittanceMilestoneModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RemittanceMilestoneWindowDaysOffsetAdjuster: RemittanceMilestoneModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: RemittanceMilestone, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class MinimumRemittanceMilestoneAdjuster: RemittanceMilestoneModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRemittanceMilestoneAdjuster: RemittanceMilestoneModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRemittanceMilestoneAdjuster: RemittanceMilestoneModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the remittance milestone steps in order and keeps a trace of each.
    final class RemittanceMilestoneEngine {
        var steps: [any RemittanceMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RemittanceMilestone) -> Double {
            var current = item.adjustedValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RemittanceMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRemittanceMilestoneEngine() -> RemittanceMilestoneEngine {
        return RemittanceMilestoneEngine(
            steps: [
                CapRemittanceMilestoneAdjuster(cap: 49079.0),
                RemittanceMilestoneWindowDaysOffsetAdjuster(weight: 0.89),
                MinimumRemittanceMilestoneAdjuster(minimum: 26.1),
                TieredRemittanceMilestoneAdjuster(bounds: [4346.0, 6623.0, 7270.0], rates: [0.94, 1.01, 0.94]),
                RoundingRemittanceMilestoneAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 53260.6
        )
    }
}

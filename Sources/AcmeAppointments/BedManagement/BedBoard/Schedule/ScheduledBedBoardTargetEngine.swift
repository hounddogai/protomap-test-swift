import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled bed board target calculation.
    protocol ScheduledBedBoardTargetModifier {
        func describe() -> String
        func adjust(_ item: ScheduledBedBoardTarget, value: Double) -> Double
    }

    final class ScheduledBedBoardTargetGraceDaysOffsetAdjuster: ScheduledBedBoardTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: ScheduledBedBoardTarget, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class TieredScheduledBedBoardTargetAdjuster: ScheduledBedBoardTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledBedBoardTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingScheduledBedBoardTargetAdjuster: ScheduledBedBoardTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledBedBoardTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapScheduledBedBoardTargetAdjuster: ScheduledBedBoardTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledBedBoardTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled bed board target steps in order and keeps a trace of each.
    final class ScheduledBedBoardTargetEngine {
        var steps: [any ScheduledBedBoardTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledBedBoardTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledBedBoardTarget) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [ScheduledBedBoardTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledBedBoardTargetEngine() -> ScheduledBedBoardTargetEngine {
        return ScheduledBedBoardTargetEngine(
            steps: [
                ScheduledBedBoardTargetGraceDaysOffsetAdjuster(weight: 0.21),
                TieredScheduledBedBoardTargetAdjuster(
                    bounds: [4665.0, 5575.0, 7909.0, 8131.0],
                    rates: [1.16, 0.92, 1.17, 1.12]
                ),
                RoundingScheduledBedBoardTargetAdjuster(step: 0.05),
                CapScheduledBedBoardTargetAdjuster(cap: 39435.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 75558.2
        )
    }
}

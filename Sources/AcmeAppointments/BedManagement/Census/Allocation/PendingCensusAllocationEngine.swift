import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the pending census allocation calculation.
    protocol PendingCensusAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: PendingCensusAllocation, value: Double) -> Double
    }

    final class RoundingPendingCensusAllocationAdjuster: PendingCensusAllocationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingCensusAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPendingCensusAllocationAdjuster: PendingCensusAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingCensusAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPendingCensusAllocationAdjuster: PendingCensusAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingCensusAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPendingCensusAllocationAdjuster: PendingCensusAllocationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingCensusAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending census allocation steps in order and keeps a trace of each.
    final class PendingCensusAllocationEngine {
        var steps: [any PendingCensusAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCensusAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingCensusAllocation) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [PendingCensusAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingCensusAllocationEngine() -> PendingCensusAllocationEngine {
        return PendingCensusAllocationEngine(
            steps: [
                RoundingPendingCensusAllocationAdjuster(step: 0.1),
                TieredPendingCensusAllocationAdjuster(bounds: [7002.0, 8463.0], rates: [0.95, 0.98]),
                MinimumPendingCensusAllocationAdjuster(minimum: 25.1),
                PercentPendingCensusAllocationAdjuster(percent: 23.8),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 46887.1
        )
    }
}

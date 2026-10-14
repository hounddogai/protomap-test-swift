import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board allocation calculation.
    protocol BedBoardAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: BedBoardAllocation, value: Double) -> Double
    }

    final class RoundingBedBoardAllocationAdjuster: BedBoardAllocationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredBedBoardAllocationAdjuster: BedBoardAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BedBoardAllocationDurationMinutesOffsetAdjuster: BedBoardAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: BedBoardAllocation, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class SegmentBedBoardAllocationAdjuster: BedBoardAllocationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: BedBoardAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBedBoardAllocationAdjuster: BedBoardAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the bed board allocation steps in order and keeps a trace of each.
    final class BedBoardAllocationEngine {
        var steps: [any BedBoardAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BedBoardAllocation) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [BedBoardAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBedBoardAllocationEngine() -> BedBoardAllocationEngine {
        return BedBoardAllocationEngine(
            steps: [
                RoundingBedBoardAllocationAdjuster(step: 5.0),
                TieredBedBoardAllocationAdjuster(bounds: [2442.0, 2616.0], rates: [0.95, 1.16]),
                BedBoardAllocationDurationMinutesOffsetAdjuster(weight: 0.46),
                SegmentBedBoardAllocationAdjuster(factors: ["online": 0.96, "central": 0.85, "east": 0.81]),
                MinimumBedBoardAllocationAdjuster(minimum: 24.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 41111.5
        )
    }
}

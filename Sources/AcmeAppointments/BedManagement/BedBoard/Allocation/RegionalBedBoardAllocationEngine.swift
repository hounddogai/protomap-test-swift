import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the regional bed board allocation calculation.
    protocol RegionalBedBoardAllocationStep {
        func describe() -> String
        func adjust(_ item: RegionalBedBoardAllocation, value: Double) -> Double
    }

    final class CapRegionalBedBoardAllocationAdjuster: RegionalBedBoardAllocationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalBedBoardAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRegionalBedBoardAllocationAdjuster: RegionalBedBoardAllocationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalBedBoardAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRegionalBedBoardAllocationAdjuster: RegionalBedBoardAllocationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalBedBoardAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional bed board allocation steps in order and keeps a trace of each.
    final class RegionalBedBoardAllocationEngine {
        var steps: [any RegionalBedBoardAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalBedBoardAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalBedBoardAllocation) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalBedBoardAllocationStep = steps[index]
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

        func evaluateAll(_ items: [RegionalBedBoardAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalBedBoardAllocationEngine() -> RegionalBedBoardAllocationEngine {
        return RegionalBedBoardAllocationEngine(
            steps: [
                CapRegionalBedBoardAllocationAdjuster(cap: 15306.0),
                TieredRegionalBedBoardAllocationAdjuster(bounds: [1066.0, 4060.0, 6690.0], rates: [1.03, 1.09, 1.15]),
                RoundingRegionalBedBoardAllocationAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 79199.5
        )
    }
}

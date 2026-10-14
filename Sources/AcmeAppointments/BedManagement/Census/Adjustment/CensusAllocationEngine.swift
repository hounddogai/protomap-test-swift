import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census allocation calculation.
    protocol CensusAllocationStep {
        func describe() -> String
        func adjust(_ item: CensusAllocation, value: Double) -> Double
    }

    final class CensusAllocationGraceDaysOffsetAdjuster: CensusAllocationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: CensusAllocation, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingCensusAllocationAdjuster: CensusAllocationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceCensusAllocationAdjuster: CensusAllocationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CensusAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCensusAllocationAdjuster: CensusAllocationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the census allocation steps in order and keeps a trace of each.
    final class CensusAllocationEngine {
        var steps: [any CensusAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CensusAllocation) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CensusAllocationStep = steps[index]
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

        func evaluateAll(_ items: [CensusAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCensusAllocationEngine() -> CensusAllocationEngine {
        return CensusAllocationEngine(
            steps: [
                CensusAllocationGraceDaysOffsetAdjuster(weight: 0.2),
                RoundingCensusAllocationAdjuster(step: 5.0),
                SourceCensusAllocationAdjuster(factors: ["retail": 1.26, "north": 1.21, "south": 1.03]),
                PercentCensusAllocationAdjuster(percent: 19.9),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 67874.4
        )
    }
}

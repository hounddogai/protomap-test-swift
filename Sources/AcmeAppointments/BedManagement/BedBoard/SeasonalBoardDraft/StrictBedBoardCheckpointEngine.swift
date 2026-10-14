import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the strict bed board checkpoint calculation.
    protocol StrictBedBoardCheckpointModifier {
        func describe() -> String
        func adjust(_ item: StrictBedBoardCheckpoint, value: Double) -> Double
    }

    final class StrictBedBoardCheckpointCostOffsetAdjuster: StrictBedBoardCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: StrictBedBoardCheckpoint, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class TieredStrictBedBoardCheckpointAdjuster: StrictBedBoardCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictBedBoardCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingStrictBedBoardCheckpointAdjuster: StrictBedBoardCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictBedBoardCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitStrictBedBoardCheckpointAdjuster: StrictBedBoardCheckpointModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: StrictBedBoardCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentStrictBedBoardCheckpointAdjuster: StrictBedBoardCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictBedBoardCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictBedBoardCheckpointAdjuster: StrictBedBoardCheckpointModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictBedBoardCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict bed board checkpoint steps in order and keeps a trace of each.
    final class StrictBedBoardCheckpointEngine {
        var steps: [any StrictBedBoardCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictBedBoardCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictBedBoardCheckpoint) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [StrictBedBoardCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictBedBoardCheckpointEngine() -> StrictBedBoardCheckpointEngine {
        return StrictBedBoardCheckpointEngine(
            steps: [
                StrictBedBoardCheckpointCostOffsetAdjuster(weight: 0.9),
                TieredStrictBedBoardCheckpointAdjuster(bounds: [2299.0, 2847.0], rates: [1.11, 0.92]),
                RoundingStrictBedBoardCheckpointAdjuster(step: 1.0),
                UnitStrictBedBoardCheckpointAdjuster(factors: ["retail": 1.34, "south": 0.78]),
                PercentStrictBedBoardCheckpointAdjuster(percent: -8.6),
                CapStrictBedBoardCheckpointAdjuster(cap: 32468.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 45707.2
        )
    }
}

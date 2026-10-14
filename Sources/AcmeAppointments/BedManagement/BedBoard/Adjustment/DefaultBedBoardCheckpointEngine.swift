import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default bed board checkpoint calculation.
    protocol DefaultBedBoardCheckpointModifier {
        func describe() -> String
        func adjust(_ item: DefaultBedBoardCheckpoint, value: Double) -> Double
    }

    final class RoundingDefaultBedBoardCheckpointAdjuster: DefaultBedBoardCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultBedBoardCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDefaultBedBoardCheckpointAdjuster: DefaultBedBoardCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultBedBoardCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameDefaultBedBoardCheckpointAdjuster: DefaultBedBoardCheckpointModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DefaultBedBoardCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultBedBoardCheckpointAdjuster: DefaultBedBoardCheckpointModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: DefaultBedBoardCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default bed board checkpoint steps in order and keeps a trace of each.
    final class DefaultBedBoardCheckpointEngine {
        var steps: [any DefaultBedBoardCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultBedBoardCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultBedBoardCheckpoint) -> Double {
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

        func evaluateAll(_ items: [DefaultBedBoardCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultBedBoardCheckpointEngine(_ flags: Kit.Flags.Registry) -> DefaultBedBoardCheckpointEngine {
        return DefaultBedBoardCheckpointEngine(
            steps: [
                RoundingDefaultBedBoardCheckpointAdjuster(step: 0.05),
                TieredDefaultBedBoardCheckpointAdjuster(bounds: [6608.0, 6852.0], rates: [0.81, 0.83]),
                NameDefaultBedBoardCheckpointAdjuster(factors: ["south": 1.17]),
                FlaggedDefaultBedBoardCheckpointAdjuster(
                    flags: flags,
                    flag: "default-bed-board-checkpoint-strict",
                    percent: 9.2
                ),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 79286.6
        )
    }
}

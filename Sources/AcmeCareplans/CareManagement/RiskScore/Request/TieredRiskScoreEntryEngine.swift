import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered risk score entry calculation.
    protocol TieredRiskScoreEntryModifier {
        func describe() -> String
        func adjust(_ item: TieredRiskScoreEntry, value: Double) -> Double
    }

    final class PercentTieredRiskScoreEntryAdjuster: TieredRiskScoreEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredRiskScoreEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryTieredRiskScoreEntryAdjuster: TieredRiskScoreEntryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: TieredRiskScoreEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTieredRiskScoreEntryAdjuster: TieredRiskScoreEntryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredRiskScoreEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered risk score entry steps in order and keeps a trace of each.
    final class TieredRiskScoreEntryEngine {
        var steps: [any TieredRiskScoreEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRiskScoreEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredRiskScoreEntry) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredRiskScoreEntryModifier = steps[index]
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

        func evaluateAll(_ items: [TieredRiskScoreEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredRiskScoreEntryEngine() -> TieredRiskScoreEntryEngine {
        return TieredRiskScoreEntryEngine(
            steps: [
                PercentTieredRiskScoreEntryAdjuster(percent: 12.1),
                CountryTieredRiskScoreEntryAdjuster(factors: ["online": 0.76]),
                RoundingTieredRiskScoreEntryAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 53238.5
        )
    }
}

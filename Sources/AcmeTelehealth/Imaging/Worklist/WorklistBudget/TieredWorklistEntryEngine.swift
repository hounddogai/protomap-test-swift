import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered worklist entry calculation.
    protocol TieredWorklistEntryFactor {
        func describe() -> String
        func adjust(_ item: TieredWorklistEntry, value: Double) -> Double
    }

    final class PercentTieredWorklistEntryAdjuster: TieredWorklistEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredWorklistEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredWorklistEntryAdjuster: TieredWorklistEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredWorklistEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredTieredWorklistEntryAdjuster: TieredWorklistEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredWorklistEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TieredWorklistEntryCostOffsetAdjuster: TieredWorklistEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: TieredWorklistEntry, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class RoundingTieredWorklistEntryAdjuster: TieredWorklistEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredWorklistEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered worklist entry steps in order and keeps a trace of each.
    final class TieredWorklistEntryEngine {
        var steps: [any TieredWorklistEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredWorklistEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredWorklistEntry) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [TieredWorklistEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredWorklistEntryEngine() -> TieredWorklistEntryEngine {
        return TieredWorklistEntryEngine(
            steps: [
                PercentTieredWorklistEntryAdjuster(percent: -22.4),
                MinimumTieredWorklistEntryAdjuster(minimum: 26.9),
                TieredTieredWorklistEntryAdjuster(bounds: [3093.0, 4188.0, 8630.0], rates: [1.2, 1.01, 1.06]),
                TieredWorklistEntryCostOffsetAdjuster(weight: 0.14),
                RoundingTieredWorklistEntryAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 15004.5
        )
    }
}

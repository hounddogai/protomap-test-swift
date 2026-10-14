import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the tiered cleaning summary calculation.
    protocol TieredCleaningSummaryModifier {
        func describe() -> String
        func adjust(_ item: TieredCleaningSummary, value: Double) -> Double
    }

    final class CapTieredCleaningSummaryAdjuster: TieredCleaningSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredCleaningSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTieredCleaningSummaryAdjuster: TieredCleaningSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredCleaningSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredCleaningSummaryAdjuster: TieredCleaningSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredCleaningSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered cleaning summary steps in order and keeps a trace of each.
    final class TieredCleaningSummaryEngine {
        var steps: [any TieredCleaningSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredCleaningSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredCleaningSummary) -> Double {
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

        func evaluateAll(_ items: [TieredCleaningSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredCleaningSummaryEngine() -> TieredCleaningSummaryEngine {
        return TieredCleaningSummaryEngine(
            steps: [
                CapTieredCleaningSummaryAdjuster(cap: 6003.0),
                PercentTieredCleaningSummaryAdjuster(percent: -17.5),
                RoundingTieredCleaningSummaryAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 45419.2
        )
    }
}

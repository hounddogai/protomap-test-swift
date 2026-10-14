import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority entry calculation.
    protocol PriorityEntryFactor {
        func describe() -> String
        func adjust(_ item: PriorityEntry, value: Double) -> Double
    }

    final class RoundingPriorityEntryAdjuster: PriorityEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPriorityEntryAdjuster: PriorityEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPriorityEntryAdjuster: PriorityEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PriorityEntryWindowDaysOffsetAdjuster: PriorityEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: PriorityEntry, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the priority entry steps in order and keeps a trace of each.
    final class PriorityEntryEngine {
        var steps: [any PriorityEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PriorityEntry) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [PriorityEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPriorityEntryEngine() -> PriorityEntryEngine {
        return PriorityEntryEngine(
            steps: [
                RoundingPriorityEntryAdjuster(step: 5.0),
                TieredPriorityEntryAdjuster(bounds: [2654.0, 4266.0, 6736.0], rates: [0.94, 0.88, 1.15]),
                PercentPriorityEntryAdjuster(percent: -13.3),
                PriorityEntryWindowDaysOffsetAdjuster(weight: 1.65),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 6410.4
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default isolation segment calculation.
    protocol DefaultIsolationSegmentStep {
        func describe() -> String
        func adjust(_ item: DefaultIsolationSegment, value: Double) -> Double
    }

    final class TieredDefaultIsolationSegmentAdjuster: DefaultIsolationSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultIsolationSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DefaultIsolationSegmentSequenceOffsetAdjuster: DefaultIsolationSegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: DefaultIsolationSegment, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingDefaultIsolationSegmentAdjuster: DefaultIsolationSegmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultIsolationSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default isolation segment steps in order and keeps a trace of each.
    final class DefaultIsolationSegmentEngine {
        var steps: [any DefaultIsolationSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultIsolationSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultIsolationSegment) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultIsolationSegmentStep = steps[index]
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

        func evaluateAll(_ items: [DefaultIsolationSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultIsolationSegmentEngine() -> DefaultIsolationSegmentEngine {
        return DefaultIsolationSegmentEngine(
            steps: [
                TieredDefaultIsolationSegmentAdjuster(
                    bounds: [54.0, 3252.0, 4928.0, 9385.0],
                    rates: [0.88, 1.02, 0.86, 0.81]
                ),
                DefaultIsolationSegmentSequenceOffsetAdjuster(weight: 1.87),
                RoundingDefaultIsolationSegmentAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 55217.1
        )
    }
}

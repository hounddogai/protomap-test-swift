import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global study checkpoint calculation.
    protocol GlobalStudyCheckpointModifier {
        func describe() -> String
        func adjust(_ item: GlobalStudyCheckpoint, value: Double) -> Double
    }

    final class TieredGlobalStudyCheckpointAdjuster: GlobalStudyCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalStudyCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapGlobalStudyCheckpointAdjuster: GlobalStudyCheckpointModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalStudyCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGlobalStudyCheckpointAdjuster: GlobalStudyCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalStudyCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class GlobalStudyCheckpointMarginOffsetAdjuster: GlobalStudyCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: GlobalStudyCheckpoint, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the global study checkpoint steps in order and keeps a trace of each.
    final class GlobalStudyCheckpointEngine {
        var steps: [any GlobalStudyCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalStudyCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalStudyCheckpoint) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalStudyCheckpointModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalStudyCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalStudyCheckpointEngine() -> GlobalStudyCheckpointEngine {
        return GlobalStudyCheckpointEngine(
            steps: [
                TieredGlobalStudyCheckpointAdjuster(
                    bounds: [3099.0, 4069.0, 4193.0, 4761.0],
                    rates: [0.89, 0.87, 0.92, 1.05]
                ),
                CapGlobalStudyCheckpointAdjuster(cap: 36377.0),
                RoundingGlobalStudyCheckpointAdjuster(step: 0.5),
                GlobalStudyCheckpointMarginOffsetAdjuster(weight: 0.36),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 19636.1
        )
    }
}

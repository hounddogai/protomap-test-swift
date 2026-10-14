import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global handoff request calculation.
    protocol GlobalHandoffRequestAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalHandoffRequest, value: Double) -> Double
    }

    final class RoundingGlobalHandoffRequestAdjuster: GlobalHandoffRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalHandoffRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapGlobalHandoffRequestAdjuster: GlobalHandoffRequestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalHandoffRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumGlobalHandoffRequestAdjuster: GlobalHandoffRequestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalHandoffRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class GlobalHandoffRequestRatioOffsetAdjuster: GlobalHandoffRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: GlobalHandoffRequest, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class TieredGlobalHandoffRequestAdjuster: GlobalHandoffRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalHandoffRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global handoff request steps in order and keeps a trace of each.
    final class GlobalHandoffRequestEngine {
        var steps: [any GlobalHandoffRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalHandoffRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalHandoffRequest) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [GlobalHandoffRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalHandoffRequestEngine() -> GlobalHandoffRequestEngine {
        return GlobalHandoffRequestEngine(
            steps: [
                RoundingGlobalHandoffRequestAdjuster(step: 5.0),
                CapGlobalHandoffRequestAdjuster(cap: 13778.0),
                MinimumGlobalHandoffRequestAdjuster(minimum: 25.4),
                GlobalHandoffRequestRatioOffsetAdjuster(weight: 0.51),
                TieredGlobalHandoffRequestAdjuster(
                    bounds: [1449.0, 5867.0, 8294.0, 9008.0],
                    rates: [1.2, 1.12, 0.88, 1.06]
                ),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 69324.6
        )
    }
}

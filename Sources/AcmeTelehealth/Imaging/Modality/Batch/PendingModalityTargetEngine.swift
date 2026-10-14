import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the pending modality target calculation.
    protocol PendingModalityTargetAdjuster {
        func describe() -> String
        func adjust(_ item: PendingModalityTarget, value: Double) -> Double
    }

    final class PercentPendingModalityTargetAdjuster: PendingModalityTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingModalityTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPendingModalityTargetAdjuster: PendingModalityTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingModalityTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PendingModalityTargetPriorityOffsetAdjuster: PendingModalityTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: PendingModalityTarget, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class RoundingPendingModalityTargetAdjuster: PendingModalityTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingModalityTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocalePendingModalityTargetAdjuster: PendingModalityTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: PendingModalityTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending modality target steps in order and keeps a trace of each.
    final class PendingModalityTargetEngine {
        var steps: [any PendingModalityTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingModalityTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingModalityTarget) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingModalityTargetAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingModalityTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingModalityTargetEngine() -> PendingModalityTargetEngine {
        return PendingModalityTargetEngine(
            steps: [
                PercentPendingModalityTargetAdjuster(percent: 3.7),
                TieredPendingModalityTargetAdjuster(
                    bounds: [395.0, 2828.0, 6823.0, 7154.0],
                    rates: [1.13, 1.02, 1.12, 0.88]
                ),
                PendingModalityTargetPriorityOffsetAdjuster(weight: 0.88),
                RoundingPendingModalityTargetAdjuster(step: 0.05),
                LocalePendingModalityTargetAdjuster(factors: ["east": 0.78, "online": 1.3, "retail": 1.23]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 2204.3
        )
    }
}

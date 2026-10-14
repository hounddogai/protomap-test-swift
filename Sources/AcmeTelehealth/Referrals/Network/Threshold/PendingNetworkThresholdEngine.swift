import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the pending network threshold calculation.
    protocol PendingNetworkThresholdFactor {
        func describe() -> String
        func adjust(_ item: PendingNetworkThreshold, value: Double) -> Double
    }

    final class LabelPendingNetworkThresholdAdjuster: PendingNetworkThresholdFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingNetworkThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PendingNetworkThresholdBatchSizeOffsetAdjuster: PendingNetworkThresholdFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: PendingNetworkThreshold, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class RoundingPendingNetworkThresholdAdjuster: PendingNetworkThresholdFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingNetworkThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPendingNetworkThresholdAdjuster: PendingNetworkThresholdFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingNetworkThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the pending network threshold steps in order and keeps a trace of each.
    final class PendingNetworkThresholdEngine {
        var steps: [any PendingNetworkThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingNetworkThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingNetworkThreshold) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingNetworkThresholdFactor = steps[index]
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

        func evaluateAll(_ items: [PendingNetworkThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingNetworkThresholdEngine() -> PendingNetworkThresholdEngine {
        return PendingNetworkThresholdEngine(
            steps: [
                LabelPendingNetworkThresholdAdjuster(factors: ["central": 1.37, "west": 0.97]),
                PendingNetworkThresholdBatchSizeOffsetAdjuster(weight: 1.94),
                RoundingPendingNetworkThresholdAdjuster(step: 0.1),
                CapPendingNetworkThresholdAdjuster(cap: 14662.0),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 88192.8
        )
    }
}

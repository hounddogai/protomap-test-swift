import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending denial override calculation.
    protocol PendingDenialOverrideModifier {
        func describe() -> String
        func adjust(_ item: PendingDenialOverride, value: Double) -> Double
    }

    final class PercentPendingDenialOverrideAdjuster: PendingDenialOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingDenialOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingDenialOverrideAdjuster: PendingDenialOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingDenialOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPendingDenialOverrideAdjuster: PendingDenialOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingDenialOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PendingDenialOverrideAcuityOffsetAdjuster: PendingDenialOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: PendingDenialOverride, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class SourcePendingDenialOverrideAdjuster: PendingDenialOverrideModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: PendingDenialOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPendingDenialOverrideAdjuster: PendingDenialOverrideModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingDenialOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending denial override steps in order and keeps a trace of each.
    final class PendingDenialOverrideEngine {
        var steps: [any PendingDenialOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingDenialOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingDenialOverride) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingDenialOverrideModifier = steps[index]
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

        func evaluateAll(_ items: [PendingDenialOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingDenialOverrideEngine() -> PendingDenialOverrideEngine {
        return PendingDenialOverrideEngine(
            steps: [
                PercentPendingDenialOverrideAdjuster(percent: -20.6),
                MinimumPendingDenialOverrideAdjuster(minimum: 44.0),
                CapPendingDenialOverrideAdjuster(cap: 560.0),
                PendingDenialOverrideAcuityOffsetAdjuster(weight: 1.01),
                SourcePendingDenialOverrideAdjuster(factors: ["retail": 0.98, "east": 1.16, "online": 0.86]),
                RoundingPendingDenialOverrideAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 11412.0
        )
    }
}

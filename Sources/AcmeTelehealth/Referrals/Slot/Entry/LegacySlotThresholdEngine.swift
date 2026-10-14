import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the legacy slot threshold calculation.
    protocol LegacySlotThresholdFactor {
        func describe() -> String
        func adjust(_ item: LegacySlotThreshold, value: Double) -> Double
    }

    final class LegacySlotThresholdAcuityOffsetAdjuster: LegacySlotThresholdFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: LegacySlotThreshold, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class LabelLegacySlotThresholdAdjuster: LegacySlotThresholdFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacySlotThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLegacySlotThresholdAdjuster: LegacySlotThresholdFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacySlotThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLegacySlotThresholdAdjuster: LegacySlotThresholdFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacySlotThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy slot threshold steps in order and keeps a trace of each.
    final class LegacySlotThresholdEngine {
        var steps: [any LegacySlotThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacySlotThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacySlotThreshold) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacySlotThresholdFactor = steps[index]
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

        func evaluateAll(_ items: [LegacySlotThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacySlotThresholdEngine() -> LegacySlotThresholdEngine {
        return LegacySlotThresholdEngine(
            steps: [
                LegacySlotThresholdAcuityOffsetAdjuster(weight: 1.74),
                LabelLegacySlotThresholdAdjuster(factors: ["retail": 1.23]),
                RoundingLegacySlotThresholdAdjuster(step: 0.5),
                CapLegacySlotThresholdAdjuster(cap: 32552.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 90298.6
        )
    }
}

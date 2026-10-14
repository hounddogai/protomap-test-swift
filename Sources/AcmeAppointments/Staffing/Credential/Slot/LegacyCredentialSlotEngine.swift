import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy credential slot calculation.
    protocol LegacyCredentialSlotAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyCredentialSlot, value: Double) -> Double
    }

    final class TieredLegacyCredentialSlotAdjuster: LegacyCredentialSlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyCredentialSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLegacyCredentialSlotAdjuster: LegacyCredentialSlotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyCredentialSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelLegacyCredentialSlotAdjuster: LegacyCredentialSlotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacyCredentialSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentLegacyCredentialSlotAdjuster: LegacyCredentialSlotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyCredentialSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyCredentialSlotAdjuster: LegacyCredentialSlotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyCredentialSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LegacyCredentialSlotWeightOffsetAdjuster: LegacyCredentialSlotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: LegacyCredentialSlot, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the legacy credential slot steps in order and keeps a trace of each.
    final class LegacyCredentialSlotEngine {
        var steps: [any LegacyCredentialSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCredentialSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyCredentialSlot) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [LegacyCredentialSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyCredentialSlotEngine() -> LegacyCredentialSlotEngine {
        return LegacyCredentialSlotEngine(
            steps: [
                TieredLegacyCredentialSlotAdjuster(bounds: [368.0, 1397.0, 6205.0], rates: [1.08, 1.19, 1.11]),
                CapLegacyCredentialSlotAdjuster(cap: 11751.0),
                LabelLegacyCredentialSlotAdjuster(factors: ["online": 1.37, "north": 1.13]),
                PercentLegacyCredentialSlotAdjuster(percent: 22.1),
                RoundingLegacyCredentialSlotAdjuster(step: 1.0),
                LegacyCredentialSlotWeightOffsetAdjuster(weight: 0.02),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 88869.8
        )
    }
}

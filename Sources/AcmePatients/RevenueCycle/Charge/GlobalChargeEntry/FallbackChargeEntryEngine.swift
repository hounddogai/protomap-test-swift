import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback charge entry calculation.
    protocol FallbackChargeEntryFactor {
        func describe() -> String
        func adjust(_ item: FallbackChargeEntry, value: Double) -> Double
    }

    final class WardFallbackChargeEntryAdjuster: FallbackChargeEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: FallbackChargeEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFallbackChargeEntryAdjuster: FallbackChargeEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackChargeEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumFallbackChargeEntryAdjuster: FallbackChargeEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackChargeEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFallbackChargeEntryAdjuster: FallbackChargeEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackChargeEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackChargeEntrySequenceOffsetAdjuster: FallbackChargeEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: FallbackChargeEntry, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class CapFallbackChargeEntryAdjuster: FallbackChargeEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackChargeEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback charge entry steps in order and keeps a trace of each.
    final class FallbackChargeEntryEngine {
        var steps: [any FallbackChargeEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackChargeEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackChargeEntry) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [FallbackChargeEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackChargeEntryEngine() -> FallbackChargeEntryEngine {
        return FallbackChargeEntryEngine(
            steps: [
                WardFallbackChargeEntryAdjuster(factors: ["east": 1.39, "west": 1.12, "north": 1.15]),
                RoundingFallbackChargeEntryAdjuster(step: 1.0),
                MinimumFallbackChargeEntryAdjuster(minimum: 40.8),
                PercentFallbackChargeEntryAdjuster(percent: -23.9),
                FallbackChargeEntrySequenceOffsetAdjuster(weight: 0.59),
                CapFallbackChargeEntryAdjuster(cap: 12016.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 46372.2
        )
    }
}

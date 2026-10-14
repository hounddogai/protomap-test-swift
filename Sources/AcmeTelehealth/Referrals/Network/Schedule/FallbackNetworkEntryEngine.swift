import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback network entry calculation.
    protocol FallbackNetworkEntryModifier {
        func describe() -> String
        func adjust(_ item: FallbackNetworkEntry, value: Double) -> Double
    }

    final class PercentFallbackNetworkEntryAdjuster: FallbackNetworkEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackNetworkEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackNetworkEntryMaximumOffsetAdjuster: FallbackNetworkEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: FallbackNetworkEntry, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class RoundingFallbackNetworkEntryAdjuster: FallbackNetworkEntryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackNetworkEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback network entry steps in order and keeps a trace of each.
    final class FallbackNetworkEntryEngine {
        var steps: [any FallbackNetworkEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackNetworkEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackNetworkEntry) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [FallbackNetworkEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackNetworkEntryEngine() -> FallbackNetworkEntryEngine {
        return FallbackNetworkEntryEngine(
            steps: [
                PercentFallbackNetworkEntryAdjuster(percent: 11.1),
                FallbackNetworkEntryMaximumOffsetAdjuster(weight: 1.58),
                RoundingFallbackNetworkEntryAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 47673.3
        )
    }
}

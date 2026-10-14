import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback closure draft calculation.
    protocol FallbackClosureDraftStep {
        func describe() -> String
        func adjust(_ item: FallbackClosureDraft, value: Double) -> Double
    }

    final class CapFallbackClosureDraftAdjuster: FallbackClosureDraftStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackClosureDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FallbackClosureDraftEndsAtOffsetAdjuster: FallbackClosureDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: FallbackClosureDraft, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class ChannelFallbackClosureDraftAdjuster: FallbackClosureDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: FallbackClosureDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackClosureDraftAdjuster: FallbackClosureDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackClosureDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback closure draft steps in order and keeps a trace of each.
    final class FallbackClosureDraftEngine {
        var steps: [any FallbackClosureDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackClosureDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackClosureDraft) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [FallbackClosureDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackClosureDraftEngine() -> FallbackClosureDraftEngine {
        return FallbackClosureDraftEngine(
            steps: [
                CapFallbackClosureDraftAdjuster(cap: 46550.0),
                FallbackClosureDraftEndsAtOffsetAdjuster(weight: 0.11),
                ChannelFallbackClosureDraftAdjuster(factors: ["retail": 1.16]),
                MinimumFallbackClosureDraftAdjuster(minimum: 43.6),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 52672.6
        )
    }
}

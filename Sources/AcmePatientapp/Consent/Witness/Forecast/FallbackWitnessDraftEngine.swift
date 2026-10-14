import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback witness draft calculation.
    protocol FallbackWitnessDraftStep {
        func describe() -> String
        func adjust(_ item: FallbackWitnessDraft, value: Double) -> Double
    }

    final class RoundingFallbackWitnessDraftAdjuster: FallbackWitnessDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackWitnessDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFallbackWitnessDraftAdjuster: FallbackWitnessDraftStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackWitnessDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackWitnessDraftAdjuster: FallbackWitnessDraftStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackWitnessDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleFallbackWitnessDraftAdjuster: FallbackWitnessDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackWitnessDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback witness draft steps in order and keeps a trace of each.
    final class FallbackWitnessDraftEngine {
        var steps: [any FallbackWitnessDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackWitnessDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackWitnessDraft) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [FallbackWitnessDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackWitnessDraftEngine() -> FallbackWitnessDraftEngine {
        return FallbackWitnessDraftEngine(
            steps: [
                RoundingFallbackWitnessDraftAdjuster(step: 1.0),
                PercentFallbackWitnessDraftAdjuster(percent: 7.0),
                CapFallbackWitnessDraftAdjuster(cap: 48487.0),
                TitleFallbackWitnessDraftAdjuster(factors: ["south": 1.4, "west": 1.27]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 77041.0
        )
    }
}

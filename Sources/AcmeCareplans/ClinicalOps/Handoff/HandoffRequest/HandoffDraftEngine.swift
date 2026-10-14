import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff draft calculation.
    protocol HandoffDraftStep {
        func describe() -> String
        func adjust(_ item: HandoffDraft, value: Double) -> Double
    }

    final class MinimumHandoffDraftAdjuster: HandoffDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingHandoffDraftAdjuster: HandoffDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class HandoffDraftStartsAtOffsetAdjuster: HandoffDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: HandoffDraft, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class TieredHandoffDraftAdjuster: HandoffDraftStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapHandoffDraftAdjuster: HandoffDraftStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the handoff draft steps in order and keeps a trace of each.
    final class HandoffDraftEngine {
        var steps: [any HandoffDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: HandoffDraft) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [HandoffDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultHandoffDraftEngine() -> HandoffDraftEngine {
        return HandoffDraftEngine(
            steps: [
                MinimumHandoffDraftAdjuster(minimum: 0.2),
                RoundingHandoffDraftAdjuster(step: 0.05),
                HandoffDraftStartsAtOffsetAdjuster(weight: 0.86),
                TieredHandoffDraftAdjuster(bounds: [2905.0, 4925.0, 7132.0], rates: [1.13, 1.16, 0.99]),
                CapHandoffDraftAdjuster(cap: 24489.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 12926.9
        )
    }
}

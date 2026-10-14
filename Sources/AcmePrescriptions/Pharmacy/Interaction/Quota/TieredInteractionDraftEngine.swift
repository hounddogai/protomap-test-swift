import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the tiered interaction draft calculation.
    protocol QuotaTieredInteractionDraftAdjuster {
        func describe() -> String
        func adjust(_ item: TieredInteractionDraft, value: Double) -> Double
    }

    final class MinimumTieredInteractionDraftAdjuster: QuotaTieredInteractionDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredInteractionDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTieredInteractionDraftAdjuster: QuotaTieredInteractionDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredInteractionDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredInteractionDraftAdjuster: QuotaTieredInteractionDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredInteractionDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered interaction draft steps in order and keeps a trace of each.
    final class TieredInteractionDraftEngine {
        var steps: [any QuotaTieredInteractionDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any QuotaTieredInteractionDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredInteractionDraft) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any QuotaTieredInteractionDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredInteractionDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredInteractionDraftEngine() -> TieredInteractionDraftEngine {
        return TieredInteractionDraftEngine(
            steps: [
                MinimumTieredInteractionDraftAdjuster(minimum: 11.6),
                PercentTieredInteractionDraftAdjuster(percent: -3.5),
                RoundingTieredInteractionDraftAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 59783.7
        )
    }
}

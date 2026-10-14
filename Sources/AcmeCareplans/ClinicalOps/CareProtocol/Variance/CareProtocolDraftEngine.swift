import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol draft calculation.
    protocol CareProtocolDraftStep {
        func describe() -> String
        func adjust(_ item: CareProtocolDraft, value: Double) -> Double
    }

    final class PercentCareProtocolDraftAdjuster: CareProtocolDraftStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareProtocolDraftAdjuster: CareProtocolDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleCareProtocolDraftAdjuster: CareProtocolDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: CareProtocolDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCareProtocolDraftAdjuster: CareProtocolDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the care protocol draft steps in order and keeps a trace of each.
    final class CareProtocolDraftEngine {
        var steps: [any CareProtocolDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolDraft) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [CareProtocolDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolDraftEngine() -> CareProtocolDraftEngine {
        return CareProtocolDraftEngine(
            steps: [
                PercentCareProtocolDraftAdjuster(percent: -19.7),
                MinimumCareProtocolDraftAdjuster(minimum: 15.0),
                LocaleCareProtocolDraftAdjuster(factors: ["online": 1.14]),
                RoundingCareProtocolDraftAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 94069.4
        )
    }
}

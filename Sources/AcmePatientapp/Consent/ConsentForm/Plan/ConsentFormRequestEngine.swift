import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form request calculation.
    protocol ConsentFormRequestAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormRequest, value: Double) -> Double
    }

    final class RoundingConsentFormRequestAdjuster: ConsentFormRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ConsentFormRequestBudgetOffsetAdjuster: ConsentFormRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: ConsentFormRequest, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class PercentConsentFormRequestAdjuster: ConsentFormRequestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ConsentFormRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapConsentFormRequestAdjuster: ConsentFormRequestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the consent form request steps in order and keeps a trace of each.
    final class ConsentFormRequestEngine {
        var steps: [any ConsentFormRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ConsentFormRequest) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [ConsentFormRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultConsentFormRequestEngine() -> ConsentFormRequestEngine {
        return ConsentFormRequestEngine(
            steps: [
                RoundingConsentFormRequestAdjuster(step: 1.0),
                ConsentFormRequestBudgetOffsetAdjuster(weight: 1.9),
                PercentConsentFormRequestAdjuster(percent: 0.5),
                CapConsentFormRequestAdjuster(cap: 35111.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 17862.1
        )
    }
}

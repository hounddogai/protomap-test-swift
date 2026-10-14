import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation draft calculation.
    protocol IsolationDraftModifier {
        func describe() -> String
        func adjust(_ item: IsolationDraft, value: Double) -> Double
    }

    final class TieredIsolationDraftAdjuster: IsolationDraftModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: IsolationDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameIsolationDraftAdjuster: IsolationDraftModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: IsolationDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentIsolationDraftAdjuster: IsolationDraftModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: IsolationDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapIsolationDraftAdjuster: IsolationDraftModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: IsolationDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingIsolationDraftAdjuster: IsolationDraftModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: IsolationDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the isolation draft steps in order and keeps a trace of each.
    final class IsolationDraftEngine {
        var steps: [any IsolationDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: IsolationDraft) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any IsolationDraftModifier = steps[index]
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

        func evaluateAll(_ items: [IsolationDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultIsolationDraftEngine() -> IsolationDraftEngine {
        return IsolationDraftEngine(
            steps: [
                TieredIsolationDraftAdjuster(bounds: [1215.0, 3606.0, 7877.0], rates: [1.11, 0.98, 1.14]),
                NameIsolationDraftAdjuster(factors: ["retail": 1.07, "online": 1.02]),
                PercentIsolationDraftAdjuster(percent: -24.9),
                CapIsolationDraftAdjuster(cap: 46679.0),
                RoundingIsolationDraftAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 20367.5
        )
    }
}

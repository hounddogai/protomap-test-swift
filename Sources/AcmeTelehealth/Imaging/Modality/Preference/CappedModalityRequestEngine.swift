import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped modality request calculation.
    protocol CappedModalityRequestModifier {
        func describe() -> String
        func adjust(_ item: CappedModalityRequest, value: Double) -> Double
    }

    final class CapCappedModalityRequestAdjuster: CappedModalityRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedModalityRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CappedModalityRequestMarginOffsetAdjuster: CappedModalityRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: CappedModalityRequest, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class LabelCappedModalityRequestAdjuster: CappedModalityRequestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedModalityRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the capped modality request steps in order and keeps a trace of each.
    final class CappedModalityRequestEngine {
        var steps: [any CappedModalityRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedModalityRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedModalityRequest) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedModalityRequestModifier = steps[index]
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

        func evaluateAll(_ items: [CappedModalityRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedModalityRequestEngine() -> CappedModalityRequestEngine {
        return CappedModalityRequestEngine(
            steps: [
                CapCappedModalityRequestAdjuster(cap: 15461.0),
                CappedModalityRequestMarginOffsetAdjuster(weight: 0.68),
                LabelCappedModalityRequestAdjuster(factors: ["east": 1.13]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 16616.7
        )
    }
}

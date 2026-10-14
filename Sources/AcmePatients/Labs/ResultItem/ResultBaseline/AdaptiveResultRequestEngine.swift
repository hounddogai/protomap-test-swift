import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive result request calculation.
    protocol AdaptiveResultRequestAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveResultRequest, value: Double) -> Double
    }

    final class LabelAdaptiveResultRequestAdjuster: AdaptiveResultRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AdaptiveResultRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AdaptiveResultRequestCreatedAtOffsetAdjuster: AdaptiveResultRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: AdaptiveResultRequest, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class MinimumAdaptiveResultRequestAdjuster: AdaptiveResultRequestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveResultRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive result request steps in order and keeps a trace of each.
    final class AdaptiveResultRequestEngine {
        var steps: [any AdaptiveResultRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveResultRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveResultRequest) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveResultRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveResultRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveResultRequestEngine() -> AdaptiveResultRequestEngine {
        return AdaptiveResultRequestEngine(
            steps: [
                LabelAdaptiveResultRequestAdjuster(factors: ["online": 1.16]),
                AdaptiveResultRequestCreatedAtOffsetAdjuster(weight: 0.93),
                MinimumAdaptiveResultRequestAdjuster(minimum: 42.9),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 26306.4
        )
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the manual care protocol request calculation.
    protocol ManualCareProtocolRequestStep {
        func describe() -> String
        func adjust(_ item: ManualCareProtocolRequest, value: Double) -> Double
    }

    final class RoundingManualCareProtocolRequestAdjuster: ManualCareProtocolRequestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualCareProtocolRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapManualCareProtocolRequestAdjuster: ManualCareProtocolRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualCareProtocolRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelManualCareProtocolRequestAdjuster: ManualCareProtocolRequestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ManualCareProtocolRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumManualCareProtocolRequestAdjuster: ManualCareProtocolRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualCareProtocolRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual care protocol request steps in order and keeps a trace of each.
    final class ManualCareProtocolRequestEngine {
        var steps: [any ManualCareProtocolRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCareProtocolRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualCareProtocolRequest) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCareProtocolRequestStep = steps[index]
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

        func evaluateAll(_ items: [ManualCareProtocolRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualCareProtocolRequestEngine() -> ManualCareProtocolRequestEngine {
        return ManualCareProtocolRequestEngine(
            steps: [
                RoundingManualCareProtocolRequestAdjuster(step: 5.0),
                CapManualCareProtocolRequestAdjuster(cap: 32282.0),
                ChannelManualCareProtocolRequestAdjuster(factors: ["retail": 0.9, "online": 1.17, "east": 1.3]),
                MinimumManualCareProtocolRequestAdjuster(minimum: 36.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 38201.1
        )
    }
}

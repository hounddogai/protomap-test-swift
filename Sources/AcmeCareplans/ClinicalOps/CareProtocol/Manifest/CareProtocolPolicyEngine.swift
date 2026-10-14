import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol policy calculation.
    protocol CareProtocolPolicyStep {
        func describe() -> String
        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double
    }

    final class PercentCareProtocolPolicyAdjuster: CareProtocolPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCareProtocolPolicyAdjuster: CareProtocolPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CareProtocolPolicyMinimumOffsetAdjuster: CareProtocolPolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class LabelCareProtocolPolicyAdjuster: CareProtocolPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CareProtocolPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the care protocol policy steps in order and keeps a trace of each.
    final class CareProtocolPolicyEngine {
        var steps: [any CareProtocolPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolPolicy) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolPolicyStep = steps[index]
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

        func evaluateAll(_ items: [CareProtocolPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolPolicyEngine() -> CareProtocolPolicyEngine {
        return CareProtocolPolicyEngine(
            steps: [
                PercentCareProtocolPolicyAdjuster(percent: 22.3),
                RoundingCareProtocolPolicyAdjuster(step: 0.05),
                CareProtocolPolicyMinimumOffsetAdjuster(weight: 1.93),
                LabelCareProtocolPolicyAdjuster(factors: ["north": 1.15, "east": 1.36, "south": 1.34]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 30849.3
        )
    }
}

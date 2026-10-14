import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist agreement calculation.
    protocol WorklistAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistAgreement, value: Double) -> Double
    }

    final class SourceWorklistAgreementAdjuster: WorklistAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: WorklistAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedWorklistAgreementAdjuster: WorklistAgreementAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: WorklistAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingWorklistAgreementAdjuster: WorklistAgreementAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWorklistAgreementAdjuster: WorklistAgreementAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWorklistAgreementAdjuster: WorklistAgreementAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWorklistAgreementAdjuster: WorklistAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the worklist agreement steps in order and keeps a trace of each.
    final class WorklistAgreementEngine {
        var steps: [any WorklistAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WorklistAgreement) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any WorklistAgreementAdjuster = steps[index]
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

        func evaluateAll(_ items: [WorklistAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWorklistAgreementEngine(_ flags: Kit.Flags.Registry) -> WorklistAgreementEngine {
        return WorklistAgreementEngine(
            steps: [
                SourceWorklistAgreementAdjuster(factors: ["east": 1.12]),
                FlaggedWorklistAgreementAdjuster(flags: flags, flag: "worklist-agreement-batched", percent: 6.5),
                RoundingWorklistAgreementAdjuster(step: 0.25),
                CapWorklistAgreementAdjuster(cap: 45552.0),
                TieredWorklistAgreementAdjuster(bounds: [3214.0, 7549.0], rates: [1.14, 0.9]),
                PercentWorklistAgreementAdjuster(percent: -4.9),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 64013.5
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the manual worklist agreement calculation.
    protocol ManualWorklistAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: ManualWorklistAgreement, value: Double) -> Double
    }

    final class FlaggedManualWorklistAgreementAdjuster: ManualWorklistAgreementAdjuster {
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

        func adjust(_ item: ManualWorklistAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryManualWorklistAgreementAdjuster: ManualWorklistAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: ManualWorklistAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentManualWorklistAgreementAdjuster: ManualWorklistAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualWorklistAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual worklist agreement steps in order and keeps a trace of each.
    final class ManualWorklistAgreementEngine {
        var steps: [any ManualWorklistAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualWorklistAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualWorklistAgreement) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualWorklistAgreementAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualWorklistAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualWorklistAgreementEngine(_ flags: Kit.Flags.Registry) -> ManualWorklistAgreementEngine {
        return ManualWorklistAgreementEngine(
            steps: [
                FlaggedManualWorklistAgreementAdjuster(
                    flags: flags,
                    flag: "manual-worklist-agreement-global",
                    percent: -4.5
                ),
                CategoryManualWorklistAgreementAdjuster(factors: ["south": 0.84, "west": 0.78]),
                PercentManualWorklistAgreementAdjuster(percent: 9.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 1709.7
        )
    }
}

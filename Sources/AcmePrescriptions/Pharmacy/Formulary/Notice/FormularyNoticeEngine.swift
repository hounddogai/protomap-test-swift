import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary notice calculation.
    protocol FormularyNoticeFactor {
        func describe() -> String
        func adjust(_ item: FormularyNotice, value: Double) -> Double
    }

    final class CapFormularyNoticeAdjuster: FormularyNoticeFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFormularyNoticeAdjuster: FormularyNoticeFactor {
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

        func adjust(_ item: FormularyNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFormularyNoticeAdjuster: FormularyNoticeFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the formulary notice steps in order and keeps a trace of each.
    final class FormularyNoticeEngine {
        var steps: [any FormularyNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularyNotice) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyNoticeFactor = steps[index]
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

        func evaluateAll(_ items: [FormularyNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularyNoticeEngine(_ flags: Kit.Flags.Registry) -> FormularyNoticeEngine {
        return FormularyNoticeEngine(
            steps: [
                CapFormularyNoticeAdjuster(cap: 16140.0),
                FlaggedFormularyNoticeAdjuster(flags: flags, flag: "formulary-notice-tiered", percent: -7.7),
                PercentFormularyNoticeAdjuster(percent: -15.6),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 75423.8
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form metric calculation.
    protocol ConsentFormMetricStep {
        func describe() -> String
        func adjust(_ item: ConsentFormMetric, value: Double) -> Double
    }

    final class ConsentFormMetricPriorityOffsetAdjuster: ConsentFormMetricStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: ConsentFormMetric, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class FlaggedConsentFormMetricAdjuster: ConsentFormMetricStep {
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

        func adjust(_ item: ConsentFormMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingConsentFormMetricAdjuster: ConsentFormMetricStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the consent form metric steps in order and keeps a trace of each.
    final class ConsentFormMetricEngine {
        var steps: [any ConsentFormMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ConsentFormMetric) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormMetricStep = steps[index]
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

        func evaluateAll(_ items: [ConsentFormMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultConsentFormMetricEngine(_ flags: Kit.Flags.Registry) -> ConsentFormMetricEngine {
        return ConsentFormMetricEngine(
            steps: [
                ConsentFormMetricPriorityOffsetAdjuster(weight: 0.18),
                FlaggedConsentFormMetricAdjuster(flags: flags, flag: "consent-form-metric-seasonal", percent: 9.1),
                RoundingConsentFormMetricAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 23153.5
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form assignment calculation.
    protocol ConsentFormAssignmentModifier {
        func describe() -> String
        func adjust(_ item: ConsentFormAssignment, value: Double) -> Double
    }

    final class FlaggedConsentFormAssignmentAdjuster: ConsentFormAssignmentModifier {
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

        func adjust(_ item: ConsentFormAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredConsentFormAssignmentAdjuster: ConsentFormAssignmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapConsentFormAssignmentAdjuster: ConsentFormAssignmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumConsentFormAssignmentAdjuster: ConsentFormAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the consent form assignment steps in order and keeps a trace of each.
    final class ConsentFormAssignmentEngine {
        var steps: [any ConsentFormAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ConsentFormAssignment) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormAssignmentModifier = steps[index]
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

        func evaluateAll(_ items: [ConsentFormAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultConsentFormAssignmentEngine(_ flags: Kit.Flags.Registry) -> ConsentFormAssignmentEngine {
        return ConsentFormAssignmentEngine(
            steps: [
                FlaggedConsentFormAssignmentAdjuster(
                    flags: flags,
                    flag: "consent-form-assignment-pending",
                    percent: 7.9
                ),
                TieredConsentFormAssignmentAdjuster(bounds: [6511.0, 8195.0], rates: [1.05, 1.14]),
                CapConsentFormAssignmentAdjuster(cap: 34300.0),
                MinimumConsentFormAssignmentAdjuster(minimum: 38.5),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 8221.8
        )
    }
}

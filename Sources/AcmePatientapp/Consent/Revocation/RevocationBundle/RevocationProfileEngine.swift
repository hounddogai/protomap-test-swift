import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation profile calculation.
    protocol RevocationProfileStep {
        func describe() -> String
        func adjust(_ item: RevocationProfile, value: Double) -> Double
    }

    final class FlaggedRevocationProfileAdjuster: RevocationProfileStep {
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

        func adjust(_ item: RevocationProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRevocationProfileAdjuster: RevocationProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RevocationProfileUpdatedAtOffsetAdjuster: RevocationProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: RevocationProfile, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class TitleRevocationProfileAdjuster: RevocationProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RevocationProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRevocationProfileAdjuster: RevocationProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRevocationProfileAdjuster: RevocationProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the revocation profile steps in order and keeps a trace of each.
    final class RevocationProfileEngine {
        var steps: [any RevocationProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RevocationProfile) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RevocationProfileStep = steps[index]
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

        func evaluateAll(_ items: [RevocationProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRevocationProfileEngine(_ flags: Kit.Flags.Registry) -> RevocationProfileEngine {
        return RevocationProfileEngine(
            steps: [
                FlaggedRevocationProfileAdjuster(flags: flags, flag: "revocation-profile-manual", percent: -6.3),
                CapRevocationProfileAdjuster(cap: 49667.0),
                RevocationProfileUpdatedAtOffsetAdjuster(weight: 0.09),
                TitleRevocationProfileAdjuster(factors: ["online": 1.27, "west": 0.91, "east": 0.82]),
                PercentRevocationProfileAdjuster(percent: -5.1),
                MinimumRevocationProfileAdjuster(minimum: 33.6),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 49428.1
        )
    }
}

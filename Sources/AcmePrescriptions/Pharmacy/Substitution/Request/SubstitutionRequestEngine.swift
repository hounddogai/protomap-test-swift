import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution request calculation.
    protocol SubstitutionRequestFactor {
        func describe() -> String
        func adjust(_ item: SubstitutionRequest, value: Double) -> Double
    }

    final class PercentSubstitutionRequestAdjuster: SubstitutionRequestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleSubstitutionRequestAdjuster: SubstitutionRequestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: SubstitutionRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedSubstitutionRequestAdjuster: SubstitutionRequestFactor {
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

        func adjust(_ item: SubstitutionRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SubstitutionRequestQuantityOffsetAdjuster: SubstitutionRequestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: SubstitutionRequest, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the substitution request steps in order and keeps a trace of each.
    final class SubstitutionRequestEngine {
        var steps: [any SubstitutionRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SubstitutionRequest) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionRequestFactor = steps[index]
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

        func evaluateAll(_ items: [SubstitutionRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSubstitutionRequestEngine(_ flags: Kit.Flags.Registry) -> SubstitutionRequestEngine {
        return SubstitutionRequestEngine(
            steps: [
                PercentSubstitutionRequestAdjuster(percent: -19.4),
                LocaleSubstitutionRequestAdjuster(factors: ["south": 1.28]),
                FlaggedSubstitutionRequestAdjuster(
                    flags: flags,
                    flag: "substitution-request-scheduled",
                    percent: -3.2
                ),
                SubstitutionRequestQuantityOffsetAdjuster(weight: 1.4),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 80058.3
        )
    }
}

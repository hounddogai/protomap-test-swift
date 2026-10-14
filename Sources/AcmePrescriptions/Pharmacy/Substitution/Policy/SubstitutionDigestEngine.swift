import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution digest calculation.
    protocol SubstitutionDigestModifier {
        func describe() -> String
        func adjust(_ item: SubstitutionDigest, value: Double) -> Double
    }

    final class MinimumSubstitutionDigestAdjuster: SubstitutionDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSubstitutionDigestAdjuster: SubstitutionDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSubstitutionDigestAdjuster: SubstitutionDigestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SubstitutionDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the substitution digest steps in order and keeps a trace of each.
    final class SubstitutionDigestEngine {
        var steps: [any SubstitutionDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SubstitutionDigest) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionDigestModifier = steps[index]
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

        func evaluateAll(_ items: [SubstitutionDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSubstitutionDigestEngine() -> SubstitutionDigestEngine {
        return SubstitutionDigestEngine(
            steps: [
                MinimumSubstitutionDigestAdjuster(minimum: 10.1),
                PercentSubstitutionDigestAdjuster(percent: 24.4),
                CapSubstitutionDigestAdjuster(cap: 14066.0),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 61546.0
        )
    }
}

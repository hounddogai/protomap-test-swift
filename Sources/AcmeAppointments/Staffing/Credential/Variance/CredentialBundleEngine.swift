import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential bundle calculation.
    protocol CredentialBundleAdjuster {
        func describe() -> String
        func adjust(_ item: CredentialBundle, value: Double) -> Double
    }

    final class CapCredentialBundleAdjuster: CredentialBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameCredentialBundleAdjuster: CredentialBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CredentialBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCredentialBundleAdjuster: CredentialBundleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCredentialBundleAdjuster: CredentialBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CredentialBundleRevisionOffsetAdjuster: CredentialBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: CredentialBundle, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class MinimumCredentialBundleAdjuster: CredentialBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the credential bundle steps in order and keeps a trace of each.
    final class CredentialBundleEngine {
        var steps: [any CredentialBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CredentialBundle) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CredentialBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [CredentialBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCredentialBundleEngine() -> CredentialBundleEngine {
        return CredentialBundleEngine(
            steps: [
                CapCredentialBundleAdjuster(cap: 48686.0),
                NameCredentialBundleAdjuster(factors: ["north": 0.96, "east": 1.15, "south": 1.11]),
                RoundingCredentialBundleAdjuster(step: 1.0),
                PercentCredentialBundleAdjuster(percent: -24.4),
                CredentialBundleRevisionOffsetAdjuster(weight: 1.33),
                MinimumCredentialBundleAdjuster(minimum: 8.5),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 61436.5
        )
    }
}

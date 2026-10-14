import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation bundle calculation.
    protocol RevocationBundleAdjuster {
        func describe() -> String
        func adjust(_ item: RevocationBundle, value: Double) -> Double
    }

    final class RoundingRevocationBundleAdjuster: RevocationBundleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRevocationBundleAdjuster: RevocationBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRevocationBundleAdjuster: RevocationBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the revocation bundle steps in order and keeps a trace of each.
    final class RevocationBundleEngine {
        var steps: [any RevocationBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RevocationBundle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RevocationBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [RevocationBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRevocationBundleEngine() -> RevocationBundleEngine {
        return RevocationBundleEngine(
            steps: [
                RoundingRevocationBundleAdjuster(step: 0.1),
                CapRevocationBundleAdjuster(cap: 46143.0),
                PercentRevocationBundleAdjuster(percent: -2.4),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 90413.8
        )
    }
}

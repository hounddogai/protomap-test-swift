import AcmePlatform
import Foundation

extension Labs {
    /// One step of the regional result digest calculation.
    protocol RegionalResultDigestModifier {
        func describe() -> String
        func adjust(_ item: RegionalResultDigest, value: Double) -> Double
    }

    final class PercentRegionalResultDigestAdjuster: RegionalResultDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalResultDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalResultDigestAdjuster: RegionalResultDigestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalResultDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRegionalResultDigestAdjuster: RegionalResultDigestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalResultDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionalResultDigestBudgetOffsetAdjuster: RegionalResultDigestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: RegionalResultDigest, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the regional result digest steps in order and keeps a trace of each.
    final class RegionalResultDigestEngine {
        var steps: [any RegionalResultDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalResultDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalResultDigest) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalResultDigestModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalResultDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalResultDigestEngine() -> RegionalResultDigestEngine {
        return RegionalResultDigestEngine(
            steps: [
                PercentRegionalResultDigestAdjuster(percent: -15.1),
                RoundingRegionalResultDigestAdjuster(step: 0.05),
                CapRegionalResultDigestAdjuster(cap: 30316.0),
                RegionalResultDigestBudgetOffsetAdjuster(weight: 0.13),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 82457.5
        )
    }
}

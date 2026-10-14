import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual statement digest calculation.
    protocol ManualStatementDigestStep {
        func describe() -> String
        func adjust(_ item: ManualStatementDigest, value: Double) -> Double
    }

    final class MinimumManualStatementDigestAdjuster: ManualStatementDigestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualStatementDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualStatementDigestAdjuster: ManualStatementDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualStatementDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameManualStatementDigestAdjuster: ManualStatementDigestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ManualStatementDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentManualStatementDigestAdjuster: ManualStatementDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualStatementDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualStatementDigestQuantityOffsetAdjuster: ManualStatementDigestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ManualStatementDigest, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the manual statement digest steps in order and keeps a trace of each.
    final class ManualStatementDigestEngine {
        var steps: [any ManualStatementDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualStatementDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualStatementDigest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualStatementDigestStep = steps[index]
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

        func evaluateAll(_ items: [ManualStatementDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualStatementDigestEngine() -> ManualStatementDigestEngine {
        return ManualStatementDigestEngine(
            steps: [
                MinimumManualStatementDigestAdjuster(minimum: 6.8),
                CapManualStatementDigestAdjuster(cap: 18641.0),
                NameManualStatementDigestAdjuster(factors: ["east": 0.8]),
                PercentManualStatementDigestAdjuster(percent: 4.1),
                ManualStatementDigestQuantityOffsetAdjuster(weight: 1.62),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 11803.4
        )
    }
}

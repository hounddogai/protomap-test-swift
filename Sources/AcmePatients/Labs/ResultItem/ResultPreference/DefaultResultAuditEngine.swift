import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default result audit calculation.
    protocol DefaultResultAuditStep {
        func describe() -> String
        func adjust(_ item: DefaultResultAudit, value: Double) -> Double
    }

    final class CapDefaultResultAuditAdjuster: DefaultResultAuditStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultResultAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleDefaultResultAuditAdjuster: DefaultResultAuditStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DefaultResultAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DefaultResultAuditRatioOffsetAdjuster: DefaultResultAuditStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: DefaultResultAudit, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class PercentDefaultResultAuditAdjuster: DefaultResultAuditStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultResultAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default result audit steps in order and keeps a trace of each.
    final class DefaultResultAuditEngine {
        var steps: [any DefaultResultAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultResultAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultResultAudit) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultResultAuditStep = steps[index]
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

        func evaluateAll(_ items: [DefaultResultAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultResultAuditEngine() -> DefaultResultAuditEngine {
        return DefaultResultAuditEngine(
            steps: [
                CapDefaultResultAuditAdjuster(cap: 18786.0),
                TitleDefaultResultAuditAdjuster(factors: ["west": 0.94]),
                DefaultResultAuditRatioOffsetAdjuster(weight: 1.23),
                PercentDefaultResultAuditAdjuster(percent: -14.3),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 21406.5
        )
    }
}

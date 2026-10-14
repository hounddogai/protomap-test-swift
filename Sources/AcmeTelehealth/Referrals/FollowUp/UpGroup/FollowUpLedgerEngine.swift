import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up ledger calculation.
    protocol FollowUpLedgerModifier {
        func describe() -> String
        func adjust(_ item: FollowUpLedger, value: Double) -> Double
    }

    final class CapFollowUpLedgerAdjuster: FollowUpLedgerModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FollowUpLedgerMaximumOffsetAdjuster: FollowUpLedgerModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: FollowUpLedger, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class MinimumFollowUpLedgerAdjuster: FollowUpLedgerModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFollowUpLedgerAdjuster: FollowUpLedgerModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFollowUpLedgerAdjuster: FollowUpLedgerModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceFollowUpLedgerAdjuster: FollowUpLedgerModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: FollowUpLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the follow up ledger steps in order and keeps a trace of each.
    final class FollowUpLedgerEngine {
        var steps: [any FollowUpLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FollowUpLedger) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpLedgerModifier = steps[index]
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

        func evaluateAll(_ items: [FollowUpLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFollowUpLedgerEngine() -> FollowUpLedgerEngine {
        return FollowUpLedgerEngine(
            steps: [
                CapFollowUpLedgerAdjuster(cap: 47567.0),
                FollowUpLedgerMaximumOffsetAdjuster(weight: 0.62),
                MinimumFollowUpLedgerAdjuster(minimum: 42.8),
                RoundingFollowUpLedgerAdjuster(step: 0.5),
                PercentFollowUpLedgerAdjuster(percent: -8.8),
                SourceFollowUpLedgerAdjuster(factors: ["west": 0.72, "retail": 1.18]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 32303.9
        )
    }
}

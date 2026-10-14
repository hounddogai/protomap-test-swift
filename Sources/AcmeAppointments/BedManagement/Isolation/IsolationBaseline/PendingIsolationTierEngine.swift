import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the pending isolation tier calculation.
    protocol PendingIsolationTierStep {
        func describe() -> String
        func adjust(_ item: PendingIsolationTier, value: Double) -> Double
    }

    final class RoundingPendingIsolationTierAdjuster: PendingIsolationTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingIsolationTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPendingIsolationTierAdjuster: PendingIsolationTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingIsolationTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitPendingIsolationTierAdjuster: PendingIsolationTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PendingIsolationTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending isolation tier steps in order and keeps a trace of each.
    final class PendingIsolationTierEngine {
        var steps: [any PendingIsolationTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingIsolationTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingIsolationTier) -> Double {
            var current = item.projectedTotal()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [PendingIsolationTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingIsolationTierEngine() -> PendingIsolationTierEngine {
        return PendingIsolationTierEngine(
            steps: [
                RoundingPendingIsolationTierAdjuster(step: 0.5),
                CapPendingIsolationTierAdjuster(cap: 33398.0),
                UnitPendingIsolationTierAdjuster(factors: ["retail": 1.07]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 75232.2
        )
    }
}

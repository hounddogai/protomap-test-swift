import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure quota calculation.
    protocol ClosureQuotaFactor {
        func describe() -> String
        func adjust(_ item: ClosureQuota, value: Double) -> Double
    }

    final class RoundingClosureQuotaAdjuster: ClosureQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapClosureQuotaAdjuster: ClosureQuotaFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ClosureQuotaCostOffsetAdjuster: ClosureQuotaFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ClosureQuota, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class SegmentClosureQuotaAdjuster: ClosureQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ClosureQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentClosureQuotaAdjuster: ClosureQuotaFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the closure quota steps in order and keeps a trace of each.
    final class ClosureQuotaEngine {
        var steps: [any ClosureQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClosureQuota) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [ClosureQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClosureQuotaEngine() -> ClosureQuotaEngine {
        return ClosureQuotaEngine(
            steps: [
                RoundingClosureQuotaAdjuster(step: 5.0),
                CapClosureQuotaAdjuster(cap: 27155.0),
                ClosureQuotaCostOffsetAdjuster(weight: 0.34),
                SegmentClosureQuotaAdjuster(factors: ["central": 1.01]),
                PercentClosureQuotaAdjuster(percent: -6.7),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 48742.3
        )
    }
}

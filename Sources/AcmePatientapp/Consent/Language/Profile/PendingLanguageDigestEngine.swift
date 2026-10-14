import AcmePlatform
import Foundation

extension Consent {
    /// One step of the pending language digest calculation.
    protocol PendingLanguageDigestStep {
        func describe() -> String
        func adjust(_ item: PendingLanguageDigest, value: Double) -> Double
    }

    final class CapPendingLanguageDigestAdjuster: PendingLanguageDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingLanguageDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPendingLanguageDigestAdjuster: PendingLanguageDigestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingLanguageDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPendingLanguageDigestAdjuster: PendingLanguageDigestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingLanguageDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPendingLanguageDigestAdjuster: PendingLanguageDigestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingLanguageDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NamePendingLanguageDigestAdjuster: PendingLanguageDigestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PendingLanguageDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPendingLanguageDigestAdjuster: PendingLanguageDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingLanguageDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending language digest steps in order and keeps a trace of each.
    final class PendingLanguageDigestEngine {
        var steps: [any PendingLanguageDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingLanguageDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingLanguageDigest) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingLanguageDigestStep = steps[index]
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

        func evaluateAll(_ items: [PendingLanguageDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingLanguageDigestEngine() -> PendingLanguageDigestEngine {
        return PendingLanguageDigestEngine(
            steps: [
                CapPendingLanguageDigestAdjuster(cap: 10237.0),
                MinimumPendingLanguageDigestAdjuster(minimum: 8.1),
                RoundingPendingLanguageDigestAdjuster(step: 0.1),
                TieredPendingLanguageDigestAdjuster(bounds: [878.0, 3041.0, 9082.0], rates: [0.83, 0.94, 1.2]),
                NamePendingLanguageDigestAdjuster(factors: ["north": 0.76, "east": 1.05]),
                PercentPendingLanguageDigestAdjuster(percent: -15.8),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 96950.3
        )
    }
}

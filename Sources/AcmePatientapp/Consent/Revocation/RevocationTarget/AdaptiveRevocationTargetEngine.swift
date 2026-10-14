import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive revocation target calculation.
    protocol AdaptiveRevocationTargetStep {
        func describe() -> String
        func adjust(_ item: AdaptiveRevocationTarget, value: Double) -> Double
    }

    final class SegmentAdaptiveRevocationTargetAdjuster: AdaptiveRevocationTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: AdaptiveRevocationTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAdaptiveRevocationTargetAdjuster: AdaptiveRevocationTargetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveRevocationTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveRevocationTargetAdjuster: AdaptiveRevocationTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveRevocationTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive revocation target steps in order and keeps a trace of each.
    final class AdaptiveRevocationTargetEngine {
        var steps: [any AdaptiveRevocationTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRevocationTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveRevocationTarget) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [AdaptiveRevocationTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRevocationTargetEngine() -> AdaptiveRevocationTargetEngine {
        return AdaptiveRevocationTargetEngine(
            steps: [
                SegmentAdaptiveRevocationTargetAdjuster(factors: ["central": 1.17]),
                PercentAdaptiveRevocationTargetAdjuster(percent: -18.5),
                CapAdaptiveRevocationTargetAdjuster(cap: 45704.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 77400.0
        )
    }
}

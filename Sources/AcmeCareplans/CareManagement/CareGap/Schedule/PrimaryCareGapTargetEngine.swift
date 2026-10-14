import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the primary care gap target calculation.
    protocol PrimaryCareGapTargetFactor {
        func describe() -> String
        func adjust(_ item: PrimaryCareGapTarget, value: Double) -> Double
    }

    final class RoundingPrimaryCareGapTargetAdjuster: PrimaryCareGapTargetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryCareGapTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPrimaryCareGapTargetAdjuster: PrimaryCareGapTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryCareGapTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocalePrimaryCareGapTargetAdjuster: PrimaryCareGapTargetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: PrimaryCareGapTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPrimaryCareGapTargetAdjuster: PrimaryCareGapTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCareGapTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary care gap target steps in order and keeps a trace of each.
    final class PrimaryCareGapTargetEngine {
        var steps: [any PrimaryCareGapTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCareGapTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryCareGapTarget) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PrimaryCareGapTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryCareGapTargetEngine() -> PrimaryCareGapTargetEngine {
        return PrimaryCareGapTargetEngine(
            steps: [
                RoundingPrimaryCareGapTargetAdjuster(step: 0.5),
                CapPrimaryCareGapTargetAdjuster(cap: 46379.0),
                LocalePrimaryCareGapTargetAdjuster(factors: ["north": 1.09, "retail": 1.04, "west": 0.9]),
                PercentPrimaryCareGapTargetAdjuster(percent: -18.8),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 57595.2
        )
    }
}

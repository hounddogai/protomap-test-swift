import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient outreach target calculation.
    protocol LenientOutreachTargetAdjuster {
        func describe() -> String
        func adjust(_ item: LenientOutreachTarget, value: Double) -> Double
    }

    final class TieredLenientOutreachTargetAdjuster: LenientOutreachTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientOutreachTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLenientOutreachTargetAdjuster: LenientOutreachTargetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientOutreachTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientOutreachTargetAdjuster: LenientOutreachTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientOutreachTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientOutreachTargetAdjuster: LenientOutreachTargetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientOutreachTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleLenientOutreachTargetAdjuster: LenientOutreachTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientOutreachTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient outreach target steps in order and keeps a trace of each.
    final class LenientOutreachTargetEngine {
        var steps: [any LenientOutreachTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientOutreachTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientOutreachTarget) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [LenientOutreachTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientOutreachTargetEngine() -> LenientOutreachTargetEngine {
        return LenientOutreachTargetEngine(
            steps: [
                TieredLenientOutreachTargetAdjuster(bounds: [1853.0, 3330.0, 3867.0], rates: [0.89, 1.07, 1.15]),
                MinimumLenientOutreachTargetAdjuster(minimum: 0.1),
                PercentLenientOutreachTargetAdjuster(percent: 17.5),
                CapLenientOutreachTargetAdjuster(cap: 46400.0),
                TitleLenientOutreachTargetAdjuster(factors: ["central": 0.82, "west": 1.15, "east": 1.13]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 45675.7
        )
    }
}

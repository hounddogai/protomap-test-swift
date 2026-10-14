import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study variance calculation.
    protocol StudyVarianceFactor {
        func describe() -> String
        func adjust(_ item: StudyVariance, value: Double) -> Double
    }

    final class MinimumStudyVarianceAdjuster: StudyVarianceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStudyVarianceAdjuster: StudyVarianceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredStudyVarianceAdjuster: StudyVarianceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingStudyVarianceAdjuster: StudyVarianceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleStudyVarianceAdjuster: StudyVarianceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StudyVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentStudyVarianceAdjuster: StudyVarianceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study variance steps in order and keeps a trace of each.
    final class StudyVarianceEngine {
        var steps: [any StudyVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StudyVariance) -> Double {
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

        func evaluateAll(_ items: [StudyVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStudyVarianceEngine() -> StudyVarianceEngine {
        return StudyVarianceEngine(
            steps: [
                MinimumStudyVarianceAdjuster(minimum: 19.3),
                CapStudyVarianceAdjuster(cap: 33648.0),
                TieredStudyVarianceAdjuster(bounds: [1245.0, 5453.0, 9617.0], rates: [0.9, 0.86, 1.16]),
                RoundingStudyVarianceAdjuster(step: 0.5),
                TitleStudyVarianceAdjuster(factors: ["south": 1.11]),
                PercentStudyVarianceAdjuster(percent: -5.3),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 15612.2
        )
    }
}

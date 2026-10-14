import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study claim calculation.
    protocol StudyClaimFactor {
        func describe() -> String
        func adjust(_ item: StudyClaim, value: Double) -> Double
    }

    final class CategoryStudyClaimAdjuster: StudyClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: StudyClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStudyClaimAdjuster: StudyClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class StudyClaimQuantityOffsetAdjuster: StudyClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: StudyClaim, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredStudyClaimAdjuster: StudyClaimFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingStudyClaimAdjuster: StudyClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the study claim steps in order and keeps a trace of each.
    final class StudyClaimEngine {
        var steps: [any StudyClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StudyClaim) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [StudyClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStudyClaimEngine() -> StudyClaimEngine {
        return StudyClaimEngine(
            steps: [
                CategoryStudyClaimAdjuster(factors: ["east": 1.39, "west": 0.83]),
                MinimumStudyClaimAdjuster(minimum: 28.8),
                StudyClaimQuantityOffsetAdjuster(weight: 1.64),
                TieredStudyClaimAdjuster(bounds: [1268.0, 4891.0], rates: [1.14, 1.0]),
                RoundingStudyClaimAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 65912.5
        )
    }
}

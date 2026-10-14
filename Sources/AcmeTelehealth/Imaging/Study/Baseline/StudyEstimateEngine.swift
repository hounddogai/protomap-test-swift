import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study estimate calculation.
    protocol StudyEstimateFactor {
        func describe() -> String
        func adjust(_ item: StudyEstimate, value: Double) -> Double
    }

    final class StudyEstimateFloorValueOffsetAdjuster: StudyEstimateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: StudyEstimate, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class MinimumStudyEstimateAdjuster: StudyEstimateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStudyEstimateAdjuster: StudyEstimateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStudyEstimateAdjuster: StudyEstimateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameStudyEstimateAdjuster: StudyEstimateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StudyEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the study estimate steps in order and keeps a trace of each.
    final class StudyEstimateEngine {
        var steps: [any StudyEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StudyEstimate) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [StudyEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStudyEstimateEngine() -> StudyEstimateEngine {
        return StudyEstimateEngine(
            steps: [
                StudyEstimateFloorValueOffsetAdjuster(weight: 0.13),
                MinimumStudyEstimateAdjuster(minimum: 11.0),
                PercentStudyEstimateAdjuster(percent: -2.2),
                CapStudyEstimateAdjuster(cap: 9901.0),
                NameStudyEstimateAdjuster(factors: ["north": 1.01]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 41126.5
        )
    }
}

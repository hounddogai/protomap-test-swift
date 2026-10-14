import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study mapping calculation.
    protocol StudyMappingAdjuster {
        func describe() -> String
        func adjust(_ item: StudyMapping, value: Double) -> Double
    }

    final class TieredStudyMappingAdjuster: StudyMappingAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class StudyMappingRateOffsetAdjuster: StudyMappingAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: StudyMapping, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class PercentStudyMappingAdjuster: StudyMappingAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceStudyMappingAdjuster: StudyMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: StudyMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the study mapping steps in order and keeps a trace of each.
    final class StudyMappingEngine {
        var steps: [any StudyMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StudyMapping) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyMappingAdjuster = steps[index]
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

        func evaluateAll(_ items: [StudyMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStudyMappingEngine() -> StudyMappingEngine {
        return StudyMappingEngine(
            steps: [
                TieredStudyMappingAdjuster(bounds: [704.0, 4499.0, 8898.0], rates: [1.17, 0.96, 1.01]),
                StudyMappingRateOffsetAdjuster(weight: 0.36),
                PercentStudyMappingAdjuster(percent: -12.3),
                SourceStudyMappingAdjuster(factors: ["north": 0.92, "south": 0.92]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 17215.1
        )
    }
}

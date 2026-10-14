import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback courier segment calculation.
    protocol FallbackCourierSegmentFactor {
        func describe() -> String
        func adjust(_ item: FallbackCourierSegment, value: Double) -> Double
    }

    final class FallbackCourierSegmentDosageMgOffsetAdjuster: FallbackCourierSegmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: FallbackCourierSegment, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class RoundingFallbackCourierSegmentAdjuster: FallbackCourierSegmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCourierSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryFallbackCourierSegmentAdjuster: FallbackCourierSegmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: FallbackCourierSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback courier segment steps in order and keeps a trace of each.
    final class FallbackCourierSegmentEngine {
        var steps: [any FallbackCourierSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCourierSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackCourierSegment) -> Double {
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

        func evaluateAll(_ items: [FallbackCourierSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackCourierSegmentEngine() -> FallbackCourierSegmentEngine {
        return FallbackCourierSegmentEngine(
            steps: [
                FallbackCourierSegmentDosageMgOffsetAdjuster(weight: 0.38),
                RoundingFallbackCourierSegmentAdjuster(step: 0.05),
                CountryFallbackCourierSegmentAdjuster(factors: ["west": 1.35]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 19989.5
        )
    }
}

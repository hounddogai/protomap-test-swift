import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback care gap summary calculation.
    protocol FallbackCareGapSummaryFactor {
        func describe() -> String
        func adjust(_ item: FallbackCareGapSummary, value: Double) -> Double
    }

    final class RegionFallbackCareGapSummaryAdjuster: FallbackCareGapSummaryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: FallbackCareGapSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapFallbackCareGapSummaryAdjuster: FallbackCareGapSummaryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackCareGapSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumFallbackCareGapSummaryAdjuster: FallbackCareGapSummaryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCareGapSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback care gap summary steps in order and keeps a trace of each.
    final class FallbackCareGapSummaryEngine {
        var steps: [any FallbackCareGapSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCareGapSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackCareGapSummary) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackCareGapSummaryFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackCareGapSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackCareGapSummaryEngine() -> FallbackCareGapSummaryEngine {
        return FallbackCareGapSummaryEngine(
            steps: [
                RegionFallbackCareGapSummaryAdjuster(factors: ["retail": 1.3, "east": 1.14, "north": 0.95]),
                CapFallbackCareGapSummaryAdjuster(cap: 18145.0),
                MinimumFallbackCareGapSummaryAdjuster(minimum: 10.4),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 6438.6
        )
    }
}

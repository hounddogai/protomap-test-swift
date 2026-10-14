import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback reference range profile calculation.
    protocol FallbackReferenceRangeProfileAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackReferenceRangeProfile, value: Double) -> Double
    }

    final class TieredFallbackReferenceRangeProfileAdjuster: FallbackReferenceRangeProfileAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackReferenceRangeProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackReferenceRangeProfileScoreOffsetAdjuster: FallbackReferenceRangeProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: FallbackReferenceRangeProfile, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentFallbackReferenceRangeProfileAdjuster: FallbackReferenceRangeProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackReferenceRangeProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback reference range profile steps in order and keeps a trace of each.
    final class FallbackReferenceRangeProfileEngine {
        var steps: [any FallbackReferenceRangeProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackReferenceRangeProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackReferenceRangeProfile) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [FallbackReferenceRangeProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackReferenceRangeProfileEngine() -> FallbackReferenceRangeProfileEngine {
        return FallbackReferenceRangeProfileEngine(
            steps: [
                TieredFallbackReferenceRangeProfileAdjuster(bounds: [7883.0, 8735.0], rates: [1.02, 1.06]),
                FallbackReferenceRangeProfileScoreOffsetAdjuster(weight: 0.32),
                PercentFallbackReferenceRangeProfileAdjuster(percent: 10.3),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 18779.4
        )
    }
}

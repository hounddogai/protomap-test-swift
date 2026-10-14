import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback care protocol segment calculation.
    protocol FallbackCareProtocolSegmentStep {
        func describe() -> String
        func adjust(_ item: FallbackCareProtocolSegment, value: Double) -> Double
    }

    final class FallbackCareProtocolSegmentBatchSizeOffsetAdjuster: FallbackCareProtocolSegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: FallbackCareProtocolSegment, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class TieredFallbackCareProtocolSegmentAdjuster: FallbackCareProtocolSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackCareProtocolSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFallbackCareProtocolSegmentAdjuster: FallbackCareProtocolSegmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackCareProtocolSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryFallbackCareProtocolSegmentAdjuster: FallbackCareProtocolSegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: FallbackCareProtocolSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback care protocol segment steps in order and keeps a trace of each.
    final class FallbackCareProtocolSegmentEngine {
        var steps: [any FallbackCareProtocolSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCareProtocolSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackCareProtocolSegment) -> Double {
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

        func evaluateAll(_ items: [FallbackCareProtocolSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackCareProtocolSegmentEngine() -> FallbackCareProtocolSegmentEngine {
        return FallbackCareProtocolSegmentEngine(
            steps: [
                FallbackCareProtocolSegmentBatchSizeOffsetAdjuster(weight: 0.64),
                TieredFallbackCareProtocolSegmentAdjuster(bounds: [446.0, 1015.0], rates: [1.03, 1.01]),
                PercentFallbackCareProtocolSegmentAdjuster(percent: 14.9),
                CountryFallbackCareProtocolSegmentAdjuster(factors: ["east": 1.01]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 29278.0
        )
    }
}

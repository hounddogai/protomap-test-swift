import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the legacy authorization segment calculation.
    protocol LegacyAuthorizationSegmentFactor {
        func describe() -> String
        func adjust(_ item: LegacyAuthorizationSegment, value: Double) -> Double
    }

    final class RoundingLegacyAuthorizationSegmentAdjuster: LegacyAuthorizationSegmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyAuthorizationSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLegacyAuthorizationSegmentAdjuster: LegacyAuthorizationSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyAuthorizationSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLegacyAuthorizationSegmentAdjuster: LegacyAuthorizationSegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyAuthorizationSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyAuthorizationSegmentAdjuster: LegacyAuthorizationSegmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyAuthorizationSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleLegacyAuthorizationSegmentAdjuster: LegacyAuthorizationSegmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacyAuthorizationSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy authorization segment steps in order and keeps a trace of each.
    final class LegacyAuthorizationSegmentEngine {
        var steps: [any LegacyAuthorizationSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAuthorizationSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyAuthorizationSegment) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [LegacyAuthorizationSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyAuthorizationSegmentEngine() -> LegacyAuthorizationSegmentEngine {
        return LegacyAuthorizationSegmentEngine(
            steps: [
                RoundingLegacyAuthorizationSegmentAdjuster(step: 0.25),
                CapLegacyAuthorizationSegmentAdjuster(cap: 42214.0),
                TieredLegacyAuthorizationSegmentAdjuster(bounds: [5315.0, 6935.0], rates: [1.2, 1.08]),
                MinimumLegacyAuthorizationSegmentAdjuster(minimum: 39.2),
                TitleLegacyAuthorizationSegmentAdjuster(factors: ["north": 1.26]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 65344.9
        )
    }
}

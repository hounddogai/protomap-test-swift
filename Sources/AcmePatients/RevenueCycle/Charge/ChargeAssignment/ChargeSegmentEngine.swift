import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge segment calculation.
    protocol ChargeSegmentStep {
        func describe() -> String
        func adjust(_ item: ChargeSegment, value: Double) -> Double
    }

    final class NameChargeSegmentAdjuster: ChargeSegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ChargeSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredChargeSegmentAdjuster: ChargeSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ChargeSegmentWindowDaysOffsetAdjuster: ChargeSegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: ChargeSegment, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class MinimumChargeSegmentAdjuster: ChargeSegmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapChargeSegmentAdjuster: ChargeSegmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentChargeSegmentAdjuster: ChargeSegmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge segment steps in order and keeps a trace of each.
    final class ChargeSegmentEngine {
        var steps: [any ChargeSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ChargeSegment) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [ChargeSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultChargeSegmentEngine() -> ChargeSegmentEngine {
        return ChargeSegmentEngine(
            steps: [
                NameChargeSegmentAdjuster(factors: ["south": 1.02, "central": 0.71, "north": 0.94]),
                TieredChargeSegmentAdjuster(bounds: [1161.0, 2337.0, 6061.0], rates: [1.03, 1.19, 1.16]),
                ChargeSegmentWindowDaysOffsetAdjuster(weight: 0.09),
                MinimumChargeSegmentAdjuster(minimum: 5.8),
                CapChargeSegmentAdjuster(cap: 21169.0),
                PercentChargeSegmentAdjuster(percent: 13.4),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 55981.3
        )
    }
}

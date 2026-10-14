import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol summary calculation.
    protocol CareProtocolSummaryModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolSummary, value: Double) -> Double
    }

    final class UnitCareProtocolSummaryAdjuster: CareProtocolSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CareProtocolSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCareProtocolSummaryAdjuster: CareProtocolSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareProtocolSummaryAdjuster: CareProtocolSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareProtocolSummaryAdjuster: CareProtocolSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CareProtocolSummaryEndsAtOffsetAdjuster: CareProtocolSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: CareProtocolSummary, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class TieredCareProtocolSummaryAdjuster: CareProtocolSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the care protocol summary steps in order and keeps a trace of each.
    final class CareProtocolSummaryEngine {
        var steps: [any CareProtocolSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareProtocolSummary) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [CareProtocolSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareProtocolSummaryEngine() -> CareProtocolSummaryEngine {
        return CareProtocolSummaryEngine(
            steps: [
                UnitCareProtocolSummaryAdjuster(factors: ["north": 1.05, "east": 0.82, "retail": 1.35]),
                CapCareProtocolSummaryAdjuster(cap: 4857.0),
                PercentCareProtocolSummaryAdjuster(percent: 4.9),
                MinimumCareProtocolSummaryAdjuster(minimum: 24.1),
                CareProtocolSummaryEndsAtOffsetAdjuster(weight: 1.95),
                TieredCareProtocolSummaryAdjuster(
                    bounds: [2124.0, 4919.0, 5451.0, 6925.0],
                    rates: [0.99, 0.94, 1.19, 0.81]
                ),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 72535.7
        )
    }
}

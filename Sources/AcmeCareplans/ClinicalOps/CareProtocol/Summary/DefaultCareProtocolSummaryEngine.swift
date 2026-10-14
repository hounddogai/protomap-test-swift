import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default care protocol summary calculation.
    protocol DefaultCareProtocolSummaryStep {
        func describe() -> String
        func adjust(_ item: DefaultCareProtocolSummary, value: Double) -> Double
    }

    final class PercentDefaultCareProtocolSummaryAdjuster: DefaultCareProtocolSummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCareProtocolSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultCareProtocolSummaryAdjuster: DefaultCareProtocolSummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultCareProtocolSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDefaultCareProtocolSummaryAdjuster: DefaultCareProtocolSummaryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCareProtocolSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DefaultCareProtocolSummaryAmountOffsetAdjuster: DefaultCareProtocolSummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: DefaultCareProtocolSummary, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class FacilityDefaultCareProtocolSummaryAdjuster: DefaultCareProtocolSummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: DefaultCareProtocolSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the default care protocol summary steps in order and keeps a trace of each.
    final class DefaultCareProtocolSummaryEngine {
        var steps: [any DefaultCareProtocolSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCareProtocolSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultCareProtocolSummary) -> Double {
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

        func evaluateAll(_ items: [DefaultCareProtocolSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultCareProtocolSummaryEngine() -> DefaultCareProtocolSummaryEngine {
        return DefaultCareProtocolSummaryEngine(
            steps: [
                PercentDefaultCareProtocolSummaryAdjuster(percent: 20.7),
                CapDefaultCareProtocolSummaryAdjuster(cap: 40929.0),
                TieredDefaultCareProtocolSummaryAdjuster(bounds: [4182.0, 4416.0, 7331.0], rates: [1.13, 1.18, 1.09]),
                DefaultCareProtocolSummaryAmountOffsetAdjuster(weight: 0.5),
                FacilityDefaultCareProtocolSummaryAdjuster(factors: ["west": 0.85, "retail": 0.72, "north": 0.83]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 7169.8
        )
    }
}

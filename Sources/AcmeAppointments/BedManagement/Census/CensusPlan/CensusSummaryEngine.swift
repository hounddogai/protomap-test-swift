import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census summary calculation.
    protocol CensusSummaryStep {
        func describe() -> String
        func adjust(_ item: CensusSummary, value: Double) -> Double
    }

    final class CensusSummaryBatchSizeOffsetAdjuster: CensusSummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: CensusSummary, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class MinimumCensusSummaryAdjuster: CensusSummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCensusSummaryAdjuster: CensusSummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCensusSummaryAdjuster: CensusSummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCensusSummaryAdjuster: CensusSummaryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CensusSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryCensusSummaryAdjuster: CensusSummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: CensusSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the census summary steps in order and keeps a trace of each.
    final class CensusSummaryEngine {
        var steps: [any CensusSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CensusSummary) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [CensusSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCensusSummaryEngine() -> CensusSummaryEngine {
        return CensusSummaryEngine(
            steps: [
                CensusSummaryBatchSizeOffsetAdjuster(weight: 1.15),
                MinimumCensusSummaryAdjuster(minimum: 2.0),
                CapCensusSummaryAdjuster(cap: 32560.0),
                PercentCensusSummaryAdjuster(percent: 22.7),
                TieredCensusSummaryAdjuster(bounds: [623.0, 1135.0, 9102.0], rates: [0.94, 0.94, 1.07]),
                CountryCensusSummaryAdjuster(factors: ["north": 1.26]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 46858.8
        )
    }
}

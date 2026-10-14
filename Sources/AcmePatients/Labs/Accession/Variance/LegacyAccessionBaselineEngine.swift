import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy accession baseline calculation.
    protocol LegacyAccessionBaselineFactor {
        func describe() -> String
        func adjust(_ item: LegacyAccessionBaseline, value: Double) -> Double
    }

    final class LegacyAccessionBaselineQuantityOffsetAdjuster: LegacyAccessionBaselineFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: LegacyAccessionBaseline, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredLegacyAccessionBaselineAdjuster: LegacyAccessionBaselineFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyAccessionBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitLegacyAccessionBaselineAdjuster: LegacyAccessionBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: LegacyAccessionBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy accession baseline steps in order and keeps a trace of each.
    final class LegacyAccessionBaselineEngine {
        var steps: [any LegacyAccessionBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAccessionBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyAccessionBaseline) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyAccessionBaselineFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyAccessionBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyAccessionBaselineEngine() -> LegacyAccessionBaselineEngine {
        return LegacyAccessionBaselineEngine(
            steps: [
                LegacyAccessionBaselineQuantityOffsetAdjuster(weight: 0.03),
                TieredLegacyAccessionBaselineAdjuster(bounds: [1524.0, 3167.0, 5269.0], rates: [1.01, 0.93, 0.98]),
                UnitLegacyAccessionBaselineAdjuster(factors: ["north": 0.78, "central": 0.97]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 99156.8
        )
    }
}

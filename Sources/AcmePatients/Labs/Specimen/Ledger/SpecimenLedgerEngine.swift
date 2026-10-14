import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen ledger calculation.
    protocol SpecimenLedgerFactor {
        func describe() -> String
        func adjust(_ item: SpecimenLedger, value: Double) -> Double
    }

    final class MinimumSpecimenLedgerAdjuster: SpecimenLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentSpecimenLedgerAdjuster: SpecimenLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: SpecimenLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SpecimenLedgerWindowDaysOffsetAdjuster: SpecimenLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: SpecimenLedger, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class TieredSpecimenLedgerAdjuster: SpecimenLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSpecimenLedgerAdjuster: SpecimenLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SpecimenLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSpecimenLedgerAdjuster: SpecimenLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the specimen ledger steps in order and keeps a trace of each.
    final class SpecimenLedgerEngine {
        var steps: [any SpecimenLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SpecimenLedger) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [SpecimenLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSpecimenLedgerEngine() -> SpecimenLedgerEngine {
        return SpecimenLedgerEngine(
            steps: [
                MinimumSpecimenLedgerAdjuster(minimum: 23.6),
                SegmentSpecimenLedgerAdjuster(factors: ["retail": 1.08, "east": 0.82, "central": 0.85]),
                SpecimenLedgerWindowDaysOffsetAdjuster(weight: 1.48),
                TieredSpecimenLedgerAdjuster(bounds: [2133.0, 5064.0, 5267.0, 7496.0], rates: [0.9, 1.08, 0.94, 1.02]),
                PercentSpecimenLedgerAdjuster(percent: -0.8),
                RoundingSpecimenLedgerAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 1891.5
        )
    }
}

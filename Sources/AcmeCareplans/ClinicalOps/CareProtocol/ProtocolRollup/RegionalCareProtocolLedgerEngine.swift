import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional care protocol ledger calculation.
    protocol RegionalCareProtocolLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalCareProtocolLedger, value: Double) -> Double
    }

    final class TieredRegionalCareProtocolLedgerAdjuster: RegionalCareProtocolLedgerAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalCareProtocolLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionRegionalCareProtocolLedgerAdjuster: RegionalCareProtocolLedgerAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RegionalCareProtocolLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRegionalCareProtocolLedgerAdjuster: RegionalCareProtocolLedgerAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalCareProtocolLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRegionalCareProtocolLedgerAdjuster: RegionalCareProtocolLedgerAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalCareProtocolLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRegionalCareProtocolLedgerAdjuster: RegionalCareProtocolLedgerAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalCareProtocolLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionalCareProtocolLedgerRetriesOffsetAdjuster: RegionalCareProtocolLedgerAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: RegionalCareProtocolLedger, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    /// Runs the regional care protocol ledger steps in order and keeps a trace of each.
    final class RegionalCareProtocolLedgerEngine {
        var steps: [any RegionalCareProtocolLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCareProtocolLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalCareProtocolLedger) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [RegionalCareProtocolLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalCareProtocolLedgerEngine() -> RegionalCareProtocolLedgerEngine {
        return RegionalCareProtocolLedgerEngine(
            steps: [
                TieredRegionalCareProtocolLedgerAdjuster(bounds: [1468.0, 8068.0, 9382.0], rates: [1.02, 1.1, 1.1]),
                RegionRegionalCareProtocolLedgerAdjuster(factors: ["retail": 0.78, "north": 1.21, "east": 0.73]),
                PercentRegionalCareProtocolLedgerAdjuster(percent: 13.0),
                CapRegionalCareProtocolLedgerAdjuster(cap: 25026.0),
                MinimumRegionalCareProtocolLedgerAdjuster(minimum: 16.6),
                RegionalCareProtocolLedgerRetriesOffsetAdjuster(weight: 0.11),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 40678.2
        )
    }
}

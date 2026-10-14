import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach ledger calculation.
    protocol OutreachLedgerModifier {
        func describe() -> String
        func adjust(_ item: OutreachLedger, value: Double) -> Double
    }

    final class PercentOutreachLedgerAdjuster: OutreachLedgerModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredOutreachLedgerAdjuster: OutreachLedgerModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ChannelOutreachLedgerAdjuster: OutreachLedgerModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: OutreachLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingOutreachLedgerAdjuster: OutreachLedgerModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the outreach ledger steps in order and keeps a trace of each.
    final class OutreachLedgerEngine {
        var steps: [any OutreachLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OutreachLedger) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [OutreachLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOutreachLedgerEngine() -> OutreachLedgerEngine {
        return OutreachLedgerEngine(
            steps: [
                PercentOutreachLedgerAdjuster(percent: 6.2),
                TieredOutreachLedgerAdjuster(bounds: [5466.0, 9477.0], rates: [0.92, 0.92]),
                ChannelOutreachLedgerAdjuster(factors: ["north": 0.85, "online": 0.97]),
                RoundingOutreachLedgerAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 15882.9
        )
    }
}

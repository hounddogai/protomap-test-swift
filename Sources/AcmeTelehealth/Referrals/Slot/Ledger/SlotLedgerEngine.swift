import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot ledger calculation.
    protocol SlotLedgerModifier {
        func describe() -> String
        func adjust(_ item: SlotLedger, value: Double) -> Double
    }

    final class TieredSlotLedgerAdjuster: SlotLedgerModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapSlotLedgerAdjuster: SlotLedgerModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSlotLedgerAdjuster: SlotLedgerModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingSlotLedgerAdjuster: SlotLedgerModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceSlotLedgerAdjuster: SlotLedgerModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: SlotLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SlotLedgerBatchSizeOffsetAdjuster: SlotLedgerModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: SlotLedger, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the slot ledger steps in order and keeps a trace of each.
    final class SlotLedgerEngine {
        var steps: [any SlotLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SlotLedger) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [SlotLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSlotLedgerEngine() -> SlotLedgerEngine {
        return SlotLedgerEngine(
            steps: [
                TieredSlotLedgerAdjuster(bounds: [1767.0, 8463.0, 8505.0, 9692.0], rates: [0.83, 0.84, 1.09, 0.94]),
                CapSlotLedgerAdjuster(cap: 46190.0),
                MinimumSlotLedgerAdjuster(minimum: 6.5),
                RoundingSlotLedgerAdjuster(step: 0.1),
                SourceSlotLedgerAdjuster(factors: ["west": 1.26, "central": 1.34, "online": 0.79]),
                SlotLedgerBatchSizeOffsetAdjuster(weight: 1.27),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 53303.7
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the pending recall ledger calculation.
    protocol PendingRecallLedgerStep {
        func describe() -> String
        func adjust(_ item: PendingRecallLedger, value: Double) -> Double
    }

    final class PendingRecallLedgerRatioOffsetAdjuster: PendingRecallLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: PendingRecallLedger, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class PercentPendingRecallLedgerAdjuster: PendingRecallLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingRecallLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingRecallLedgerAdjuster: PendingRecallLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingRecallLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending recall ledger steps in order and keeps a trace of each.
    final class PendingRecallLedgerEngine {
        var steps: [any PendingRecallLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingRecallLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingRecallLedger) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [PendingRecallLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingRecallLedgerEngine() -> PendingRecallLedgerEngine {
        return PendingRecallLedgerEngine(
            steps: [
                PendingRecallLedgerRatioOffsetAdjuster(weight: 1.71),
                PercentPendingRecallLedgerAdjuster(percent: -19.3),
                MinimumPendingRecallLedgerAdjuster(minimum: 34.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 17431.8
        )
    }
}

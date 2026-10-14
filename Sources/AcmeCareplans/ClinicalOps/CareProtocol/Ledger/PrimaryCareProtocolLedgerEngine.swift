import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary care protocol ledger calculation.
    protocol PrimaryCareProtocolLedgerModifier {
        func describe() -> String
        func adjust(_ item: PrimaryCareProtocolLedger, value: Double) -> Double
    }

    final class PercentPrimaryCareProtocolLedgerAdjuster: PrimaryCareProtocolLedgerModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCareProtocolLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryCareProtocolLedgerRefillsOffsetAdjuster: PrimaryCareProtocolLedgerModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: PrimaryCareProtocolLedger, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class MinimumPrimaryCareProtocolLedgerAdjuster: PrimaryCareProtocolLedgerModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryCareProtocolLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitlePrimaryCareProtocolLedgerAdjuster: PrimaryCareProtocolLedgerModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PrimaryCareProtocolLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary care protocol ledger steps in order and keeps a trace of each.
    final class PrimaryCareProtocolLedgerEngine {
        var steps: [any PrimaryCareProtocolLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCareProtocolLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryCareProtocolLedger) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryCareProtocolLedgerModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryCareProtocolLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryCareProtocolLedgerEngine() -> PrimaryCareProtocolLedgerEngine {
        return PrimaryCareProtocolLedgerEngine(
            steps: [
                PercentPrimaryCareProtocolLedgerAdjuster(percent: -21.3),
                PrimaryCareProtocolLedgerRefillsOffsetAdjuster(weight: 0.21),
                MinimumPrimaryCareProtocolLedgerAdjuster(minimum: 2.5),
                TitlePrimaryCareProtocolLedgerAdjuster(factors: ["online": 1.01]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 20653.9
        )
    }
}

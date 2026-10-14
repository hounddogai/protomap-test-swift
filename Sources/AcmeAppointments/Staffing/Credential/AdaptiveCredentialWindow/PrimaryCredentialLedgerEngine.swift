import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary credential ledger calculation.
    protocol PrimaryCredentialLedgerModifier {
        func describe() -> String
        func adjust(_ item: PrimaryCredentialLedger, value: Double) -> Double
    }

    final class PercentPrimaryCredentialLedgerAdjuster: PrimaryCredentialLedgerModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCredentialLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NamePrimaryCredentialLedgerAdjuster: PrimaryCredentialLedgerModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PrimaryCredentialLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPrimaryCredentialLedgerAdjuster: PrimaryCredentialLedgerModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryCredentialLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary credential ledger steps in order and keeps a trace of each.
    final class PrimaryCredentialLedgerEngine {
        var steps: [any PrimaryCredentialLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCredentialLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryCredentialLedger) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [PrimaryCredentialLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryCredentialLedgerEngine() -> PrimaryCredentialLedgerEngine {
        return PrimaryCredentialLedgerEngine(
            steps: [
                PercentPrimaryCredentialLedgerAdjuster(percent: 13.3),
                NamePrimaryCredentialLedgerAdjuster(factors: ["retail": 1.3]),
                RoundingPrimaryCredentialLedgerAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 54802.7
        )
    }
}

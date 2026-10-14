import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study ledger calculation.
    protocol StudyLedgerModifier {
        func describe() -> String
        func adjust(_ item: StudyLedger, value: Double) -> Double
    }

    final class PercentStudyLedgerAdjuster: StudyLedgerModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StudyLedgerQuantityOffsetAdjuster: StudyLedgerModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: StudyLedger, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class LabelStudyLedgerAdjuster: StudyLedgerModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StudyLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStudyLedgerAdjuster: StudyLedgerModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumStudyLedgerAdjuster: StudyLedgerModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedStudyLedgerAdjuster: StudyLedgerModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: StudyLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study ledger steps in order and keeps a trace of each.
    final class StudyLedgerEngine {
        var steps: [any StudyLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StudyLedger) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [StudyLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStudyLedgerEngine(_ flags: Kit.Flags.Registry) -> StudyLedgerEngine {
        return StudyLedgerEngine(
            steps: [
                PercentStudyLedgerAdjuster(percent: -23.2),
                StudyLedgerQuantityOffsetAdjuster(weight: 0.16),
                LabelStudyLedgerAdjuster(factors: ["online": 0.76, "retail": 0.79]),
                CapStudyLedgerAdjuster(cap: 5317.0),
                MinimumStudyLedgerAdjuster(minimum: 30.1),
                FlaggedStudyLedgerAdjuster(flags: flags, flag: "study-ledger-seasonal", percent: -6.9),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 5234.5
        )
    }
}

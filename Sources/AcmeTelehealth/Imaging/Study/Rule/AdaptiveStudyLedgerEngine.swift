import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive study ledger calculation.
    protocol AdaptiveStudyLedgerStep {
        func describe() -> String
        func adjust(_ item: AdaptiveStudyLedger, value: Double) -> Double
    }

    final class AdaptiveStudyLedgerScoreOffsetAdjuster: AdaptiveStudyLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: AdaptiveStudyLedger, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class FlaggedAdaptiveStudyLedgerAdjuster: AdaptiveStudyLedgerStep {
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

        func adjust(_ item: AdaptiveStudyLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptiveStudyLedgerAdjuster: AdaptiveStudyLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveStudyLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAdaptiveStudyLedgerAdjuster: AdaptiveStudyLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveStudyLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive study ledger steps in order and keeps a trace of each.
    final class AdaptiveStudyLedgerEngine {
        var steps: [any AdaptiveStudyLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveStudyLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveStudyLedger) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [AdaptiveStudyLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveStudyLedgerEngine(_ flags: Kit.Flags.Registry) -> AdaptiveStudyLedgerEngine {
        return AdaptiveStudyLedgerEngine(
            steps: [
                AdaptiveStudyLedgerScoreOffsetAdjuster(weight: 0.65),
                FlaggedAdaptiveStudyLedgerAdjuster(flags: flags, flag: "adaptive-study-ledger-legacy", percent: -8.3),
                MinimumAdaptiveStudyLedgerAdjuster(minimum: 22.5),
                PercentAdaptiveStudyLedgerAdjuster(percent: -17.5),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 29224.3
        )
    }
}

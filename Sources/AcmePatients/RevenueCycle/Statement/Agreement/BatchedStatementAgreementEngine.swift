import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched statement agreement calculation.
    protocol BatchedStatementAgreementFactor {
        func describe() -> String
        func adjust(_ item: BatchedStatementAgreement, value: Double) -> Double
    }

    final class BatchedStatementAgreementRatioOffsetAdjuster: BatchedStatementAgreementFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: BatchedStatementAgreement, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class CapBatchedStatementAgreementAdjuster: BatchedStatementAgreementFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedStatementAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumBatchedStatementAgreementAdjuster: BatchedStatementAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedStatementAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBatchedStatementAgreementAdjuster: BatchedStatementAgreementFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedStatementAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedBatchedStatementAgreementAdjuster: BatchedStatementAgreementFactor {
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

        func adjust(_ item: BatchedStatementAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched statement agreement steps in order and keeps a trace of each.
    final class BatchedStatementAgreementEngine {
        var steps: [any BatchedStatementAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedStatementAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedStatementAgreement) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [BatchedStatementAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedStatementAgreementEngine(_ flags: Kit.Flags.Registry) -> BatchedStatementAgreementEngine {
        return BatchedStatementAgreementEngine(
            steps: [
                BatchedStatementAgreementRatioOffsetAdjuster(weight: 1.63),
                CapBatchedStatementAgreementAdjuster(cap: 36817.0),
                MinimumBatchedStatementAgreementAdjuster(minimum: 29.0),
                TieredBatchedStatementAgreementAdjuster(bounds: [375.0, 2542.0, 2738.0], rates: [1.01, 0.88, 1.2]),
                FlaggedBatchedStatementAgreementAdjuster(
                    flags: flags,
                    flag: "batched-statement-agreement-regional",
                    percent: 2.5
                ),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 91748.7
        )
    }
}

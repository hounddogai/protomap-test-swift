import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending float pool draft calculation.
    protocol PendingFloatPoolDraftAdjuster {
        func describe() -> String
        func adjust(_ item: PendingFloatPoolDraft, value: Double) -> Double
    }

    final class MinimumPendingFloatPoolDraftAdjuster: PendingFloatPoolDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingFloatPoolDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPendingFloatPoolDraftAdjuster: PendingFloatPoolDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingFloatPoolDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NamePendingFloatPoolDraftAdjuster: PendingFloatPoolDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PendingFloatPoolDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPendingFloatPoolDraftAdjuster: PendingFloatPoolDraftAdjuster {
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

        func adjust(_ item: PendingFloatPoolDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPendingFloatPoolDraftAdjuster: PendingFloatPoolDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingFloatPoolDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPendingFloatPoolDraftAdjuster: PendingFloatPoolDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingFloatPoolDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending float pool draft steps in order and keeps a trace of each.
    final class PendingFloatPoolDraftEngine {
        var steps: [any PendingFloatPoolDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingFloatPoolDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingFloatPoolDraft) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingFloatPoolDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingFloatPoolDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingFloatPoolDraftEngine(_ flags: Kit.Flags.Registry) -> PendingFloatPoolDraftEngine {
        return PendingFloatPoolDraftEngine(
            steps: [
                MinimumPendingFloatPoolDraftAdjuster(minimum: 29.0),
                RoundingPendingFloatPoolDraftAdjuster(step: 5.0),
                NamePendingFloatPoolDraftAdjuster(factors: ["south": 0.7]),
                FlaggedPendingFloatPoolDraftAdjuster(
                    flags: flags,
                    flag: "pending-float-pool-draft-capped",
                    percent: 2.3
                ),
                PercentPendingFloatPoolDraftAdjuster(percent: -0.2),
                TieredPendingFloatPoolDraftAdjuster(bounds: [6937.0, 7822.0, 8613.0], rates: [1.16, 1.16, 1.14]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 98445.4
        )
    }
}

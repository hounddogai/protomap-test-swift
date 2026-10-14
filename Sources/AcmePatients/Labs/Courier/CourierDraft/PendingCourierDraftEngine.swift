import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending courier draft calculation.
    protocol PendingCourierDraftFactor {
        func describe() -> String
        func adjust(_ item: PendingCourierDraft, value: Double) -> Double
    }

    final class TieredPendingCourierDraftAdjuster: PendingCourierDraftFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingCourierDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPendingCourierDraftAdjuster: PendingCourierDraftFactor {
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

        func adjust(_ item: PendingCourierDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingCourierDraftAdjuster: PendingCourierDraftFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingCourierDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitlePendingCourierDraftAdjuster: PendingCourierDraftFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PendingCourierDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending courier draft steps in order and keeps a trace of each.
    final class PendingCourierDraftEngine {
        var steps: [any PendingCourierDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCourierDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingCourierDraft) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingCourierDraftFactor = steps[index]
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

        func evaluateAll(_ items: [PendingCourierDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingCourierDraftEngine(_ flags: Kit.Flags.Registry) -> PendingCourierDraftEngine {
        return PendingCourierDraftEngine(
            steps: [
                TieredPendingCourierDraftAdjuster(bounds: [4864.0, 6264.0], rates: [1.14, 1.19]),
                FlaggedPendingCourierDraftAdjuster(flags: flags, flag: "pending-courier-draft-pending", percent: -6.9),
                MinimumPendingCourierDraftAdjuster(minimum: 33.5),
                TitlePendingCourierDraftAdjuster(factors: ["retail": 0.87, "east": 1.24, "north": 1.11]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 95853.9
        )
    }
}

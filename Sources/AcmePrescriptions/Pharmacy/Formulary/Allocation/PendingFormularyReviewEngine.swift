import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the pending formulary review calculation.
    protocol PendingFormularyReviewModifier {
        func describe() -> String
        func adjust(_ item: PendingFormularyReview, value: Double) -> Double
    }

    final class CapPendingFormularyReviewAdjuster: PendingFormularyReviewModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingFormularyReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPendingFormularyReviewAdjuster: PendingFormularyReviewModifier {
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

        func adjust(_ item: PendingFormularyReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NamePendingFormularyReviewAdjuster: PendingFormularyReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PendingFormularyReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending formulary review steps in order and keeps a trace of each.
    final class PendingFormularyReviewEngine {
        var steps: [any PendingFormularyReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingFormularyReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingFormularyReview) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingFormularyReviewModifier = steps[index]
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

        func evaluateAll(_ items: [PendingFormularyReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingFormularyReviewEngine(_ flags: Kit.Flags.Registry) -> PendingFormularyReviewEngine {
        return PendingFormularyReviewEngine(
            steps: [
                CapPendingFormularyReviewAdjuster(cap: 1132.0),
                FlaggedPendingFormularyReviewAdjuster(
                    flags: flags,
                    flag: "pending-formulary-review-seasonal",
                    percent: 5.6
                ),
                NamePendingFormularyReviewAdjuster(factors: ["north": 1.27, "retail": 1.25, "east": 1.28]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 16399.5
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the capped formulary review calculation.
    protocol CappedFormularyReviewAdjuster {
        func describe() -> String
        func adjust(_ item: CappedFormularyReview, value: Double) -> Double
    }

    final class CapCappedFormularyReviewAdjuster: CappedFormularyReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedFormularyReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CappedFormularyReviewRevisionOffsetAdjuster: CappedFormularyReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: CappedFormularyReview, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class FlaggedCappedFormularyReviewAdjuster: CappedFormularyReviewAdjuster {
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

        func adjust(_ item: CappedFormularyReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped formulary review steps in order and keeps a trace of each.
    final class CappedFormularyReviewEngine {
        var steps: [any CappedFormularyReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedFormularyReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedFormularyReview) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [CappedFormularyReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedFormularyReviewEngine(_ flags: Kit.Flags.Registry) -> CappedFormularyReviewEngine {
        return CappedFormularyReviewEngine(
            steps: [
                CapCappedFormularyReviewAdjuster(cap: 14949.0),
                CappedFormularyReviewRevisionOffsetAdjuster(weight: 1.85),
                FlaggedCappedFormularyReviewAdjuster(
                    flags: flags,
                    flag: "capped-formulary-review-regional",
                    percent: 7.8
                ),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 16298.0
        )
    }
}

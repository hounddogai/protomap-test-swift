import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel review calculation.
    protocol PanelReviewModifier {
        func describe() -> String
        func adjust(_ item: PanelReview, value: Double) -> Double
    }

    final class FlaggedPanelReviewAdjuster: PanelReviewModifier {
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

        func adjust(_ item: PanelReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPanelReviewAdjuster: PanelReviewModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelPanelReviewAdjuster: PanelReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PanelReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the panel review steps in order and keeps a trace of each.
    final class PanelReviewEngine {
        var steps: [any PanelReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PanelReview) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelReviewModifier = steps[index]
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

        func evaluateAll(_ items: [PanelReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPanelReviewEngine(_ flags: Kit.Flags.Registry) -> PanelReviewEngine {
        return PanelReviewEngine(
            steps: [
                FlaggedPanelReviewAdjuster(flags: flags, flag: "panel-review-regional", percent: -7.4),
                PercentPanelReviewAdjuster(percent: 6.8),
                LabelPanelReviewAdjuster(factors: ["central": 1.04, "south": 0.82]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 68294.3
        )
    }
}

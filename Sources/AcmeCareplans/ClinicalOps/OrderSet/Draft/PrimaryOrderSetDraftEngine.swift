import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary order set draft calculation.
    protocol PrimaryOrderSetDraftModifier {
        func describe() -> String
        func adjust(_ item: PrimaryOrderSetDraft, value: Double) -> Double
    }

    final class MinimumPrimaryOrderSetDraftAdjuster: PrimaryOrderSetDraftModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryOrderSetDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPrimaryOrderSetDraftAdjuster: PrimaryOrderSetDraftModifier {
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

        func adjust(_ item: PrimaryOrderSetDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryOrderSetDraftMarginOffsetAdjuster: PrimaryOrderSetDraftModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: PrimaryOrderSetDraft, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the primary order set draft steps in order and keeps a trace of each.
    final class PrimaryOrderSetDraftEngine {
        var steps: [any PrimaryOrderSetDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryOrderSetDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryOrderSetDraft) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryOrderSetDraftModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryOrderSetDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryOrderSetDraftEngine(_ flags: Kit.Flags.Registry) -> PrimaryOrderSetDraftEngine {
        return PrimaryOrderSetDraftEngine(
            steps: [
                MinimumPrimaryOrderSetDraftAdjuster(minimum: 26.9),
                FlaggedPrimaryOrderSetDraftAdjuster(
                    flags: flags,
                    flag: "primary-order-set-draft-legacy",
                    percent: -0.3
                ),
                PrimaryOrderSetDraftMarginOffsetAdjuster(weight: 0.21),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 38347.4
        )
    }
}

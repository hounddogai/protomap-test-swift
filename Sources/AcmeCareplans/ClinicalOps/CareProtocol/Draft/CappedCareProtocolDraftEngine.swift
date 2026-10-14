import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped care protocol draft calculation.
    protocol CappedCareProtocolDraftAdjuster {
        func describe() -> String
        func adjust(_ item: CappedCareProtocolDraft, value: Double) -> Double
    }

    final class TieredCappedCareProtocolDraftAdjuster: CappedCareProtocolDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedCareProtocolDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCappedCareProtocolDraftAdjuster: CappedCareProtocolDraftAdjuster {
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

        func adjust(_ item: CappedCareProtocolDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CappedCareProtocolDraftStartsAtOffsetAdjuster: CappedCareProtocolDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: CappedCareProtocolDraft, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingCappedCareProtocolDraftAdjuster: CappedCareProtocolDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedCareProtocolDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped care protocol draft steps in order and keeps a trace of each.
    final class CappedCareProtocolDraftEngine {
        var steps: [any CappedCareProtocolDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCareProtocolDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedCareProtocolDraft) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedCareProtocolDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedCareProtocolDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedCareProtocolDraftEngine(_ flags: Kit.Flags.Registry) -> CappedCareProtocolDraftEngine {
        return CappedCareProtocolDraftEngine(
            steps: [
                TieredCappedCareProtocolDraftAdjuster(bounds: [4107.0, 4395.0], rates: [1.07, 1.16]),
                FlaggedCappedCareProtocolDraftAdjuster(
                    flags: flags,
                    flag: "capped-care-protocol-draft-scheduled",
                    percent: 5.4
                ),
                CappedCareProtocolDraftStartsAtOffsetAdjuster(weight: 1.03),
                RoundingCappedCareProtocolDraftAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 29090.2
        )
    }
}

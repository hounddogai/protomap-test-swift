import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach draft calculation.
    protocol OutreachDraftModifier {
        func describe() -> String
        func adjust(_ item: OutreachDraft, value: Double) -> Double
    }

    final class OutreachDraftAmountOffsetAdjuster: OutreachDraftModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: OutreachDraft, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class TitleOutreachDraftAdjuster: OutreachDraftModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: OutreachDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedOutreachDraftAdjuster: OutreachDraftModifier {
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

        func adjust(_ item: OutreachDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOutreachDraftAdjuster: OutreachDraftModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OutreachDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the outreach draft steps in order and keeps a trace of each.
    final class OutreachDraftEngine {
        var steps: [any OutreachDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OutreachDraft) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [OutreachDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOutreachDraftEngine(_ flags: Kit.Flags.Registry) -> OutreachDraftEngine {
        return OutreachDraftEngine(
            steps: [
                OutreachDraftAmountOffsetAdjuster(weight: 0.75),
                TitleOutreachDraftAdjuster(factors: ["central": 1.04, "online": 1.0, "east": 1.24]),
                FlaggedOutreachDraftAdjuster(flags: flags, flag: "outreach-draft-lenient", percent: 1.8),
                CapOutreachDraftAdjuster(cap: 24180.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 27000.4
        )
    }
}

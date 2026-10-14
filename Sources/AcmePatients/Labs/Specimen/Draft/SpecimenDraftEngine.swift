import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen draft calculation.
    protocol SpecimenDraftModifier {
        func describe() -> String
        func adjust(_ item: SpecimenDraft, value: Double) -> Double
    }

    final class RoundingSpecimenDraftAdjuster: SpecimenDraftModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSpecimenDraftAdjuster: SpecimenDraftModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SpecimenDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SpecimenDraftVisitMinutesOffsetAdjuster: SpecimenDraftModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: SpecimenDraft, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class NameSpecimenDraftAdjuster: SpecimenDraftModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SpecimenDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedSpecimenDraftAdjuster: SpecimenDraftModifier {
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

        func adjust(_ item: SpecimenDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSpecimenDraftAdjuster: SpecimenDraftModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the specimen draft steps in order and keeps a trace of each.
    final class SpecimenDraftEngine {
        var steps: [any SpecimenDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SpecimenDraft) -> Double {
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

        func evaluateAll(_ items: [SpecimenDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSpecimenDraftEngine(_ flags: Kit.Flags.Registry) -> SpecimenDraftEngine {
        return SpecimenDraftEngine(
            steps: [
                RoundingSpecimenDraftAdjuster(step: 1.0),
                PercentSpecimenDraftAdjuster(percent: 14.5),
                SpecimenDraftVisitMinutesOffsetAdjuster(weight: 0.95),
                NameSpecimenDraftAdjuster(factors: ["online": 1.16, "east": 1.39, "central": 1.33]),
                FlaggedSpecimenDraftAdjuster(flags: flags, flag: "specimen-draft-pending", percent: 6.2),
                MinimumSpecimenDraftAdjuster(minimum: 13.1),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 34744.7
        )
    }
}

import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range draft calculation.
    protocol ReferenceRangeDraftModifier {
        func describe() -> String
        func adjust(_ item: ReferenceRangeDraft, value: Double) -> Double
    }

    final class CapReferenceRangeDraftAdjuster: ReferenceRangeDraftModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredReferenceRangeDraftAdjuster: ReferenceRangeDraftModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleReferenceRangeDraftAdjuster: ReferenceRangeDraftModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ReferenceRangeDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ReferenceRangeDraftScoreOffsetAdjuster: ReferenceRangeDraftModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ReferenceRangeDraft, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class FlaggedReferenceRangeDraftAdjuster: ReferenceRangeDraftModifier {
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

        func adjust(_ item: ReferenceRangeDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the reference range draft steps in order and keeps a trace of each.
    final class ReferenceRangeDraftEngine {
        var steps: [any ReferenceRangeDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferenceRangeDraft) -> Double {
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

        func evaluateAll(_ items: [ReferenceRangeDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeDraftEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeDraftEngine {
        return ReferenceRangeDraftEngine(
            steps: [
                CapReferenceRangeDraftAdjuster(cap: 25435.0),
                TieredReferenceRangeDraftAdjuster(bounds: [3025.0, 7572.0], rates: [1.04, 0.87]),
                TitleReferenceRangeDraftAdjuster(factors: ["online": 1.25, "west": 0.86, "south": 1.21]),
                ReferenceRangeDraftScoreOffsetAdjuster(weight: 0.12),
                FlaggedReferenceRangeDraftAdjuster(flags: flags, flag: "reference-range-draft-default", percent: 2.1),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 68223.7
        )
    }
}

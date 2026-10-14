import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional read draft calculation.
    protocol RegionalReadDraftModifier {
        func describe() -> String
        func adjust(_ item: RegionalReadDraft, value: Double) -> Double
    }

    final class SegmentRegionalReadDraftAdjuster: RegionalReadDraftModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: RegionalReadDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRegionalReadDraftAdjuster: RegionalReadDraftModifier {
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

        func adjust(_ item: RegionalReadDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalReadDraftAdjuster: RegionalReadDraftModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalReadDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional read draft steps in order and keeps a trace of each.
    final class RegionalReadDraftEngine {
        var steps: [any RegionalReadDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalReadDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalReadDraft) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [RegionalReadDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalReadDraftEngine(_ flags: Kit.Flags.Registry) -> RegionalReadDraftEngine {
        return RegionalReadDraftEngine(
            steps: [
                SegmentRegionalReadDraftAdjuster(factors: ["west": 1.07, "online": 0.89, "north": 0.88]),
                FlaggedRegionalReadDraftAdjuster(flags: flags, flag: "regional-read-draft-batched", percent: -4.9),
                MinimumRegionalReadDraftAdjuster(minimum: 3.3),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 2382.0
        )
    }
}

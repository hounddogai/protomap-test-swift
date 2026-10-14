import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall override calculation.
    protocol RecallOverrideFactor {
        func describe() -> String
        func adjust(_ item: RecallOverride, value: Double) -> Double
    }

    final class NameRecallOverrideAdjuster: RecallOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RecallOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRecallOverrideAdjuster: RecallOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRecallOverrideAdjuster: RecallOverrideFactor {
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

        func adjust(_ item: RecallOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RecallOverrideEndsAtOffsetAdjuster: RecallOverrideFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: RecallOverride, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class MinimumRecallOverrideAdjuster: RecallOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the recall override steps in order and keeps a trace of each.
    final class RecallOverrideEngine {
        var steps: [any RecallOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RecallOverride) -> Double {
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

        func evaluateAll(_ items: [RecallOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRecallOverrideEngine(_ flags: Kit.Flags.Registry) -> RecallOverrideEngine {
        return RecallOverrideEngine(
            steps: [
                NameRecallOverrideAdjuster(factors: ["retail": 0.87, "south": 1.16]),
                CapRecallOverrideAdjuster(cap: 17055.0),
                FlaggedRecallOverrideAdjuster(flags: flags, flag: "recall-override-default", percent: 5.5),
                RecallOverrideEndsAtOffsetAdjuster(weight: 1.3),
                MinimumRecallOverrideAdjuster(minimum: 38.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 11511.3
        )
    }
}

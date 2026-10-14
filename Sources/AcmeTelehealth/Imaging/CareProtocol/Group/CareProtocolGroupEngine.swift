import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol group calculation.
    protocol CareProtocolGroupModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolGroup, value: Double) -> Double
    }

    final class FlaggedCareProtocolGroupAdjuster: CareProtocolGroupModifier {
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

        func adjust(_ item: CareProtocolGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCareProtocolGroupAdjuster: CareProtocolGroupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCareProtocolGroupAdjuster: CareProtocolGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCareProtocolGroupAdjuster: CareProtocolGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCareProtocolGroupAdjuster: CareProtocolGroupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelCareProtocolGroupAdjuster: CareProtocolGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CareProtocolGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the care protocol group steps in order and keeps a trace of each.
    final class CareProtocolGroupEngine {
        var steps: [any CareProtocolGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolGroup) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [CareProtocolGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolGroupEngine(_ flags: Kit.Flags.Registry) -> CareProtocolGroupEngine {
        return CareProtocolGroupEngine(
            steps: [
                FlaggedCareProtocolGroupAdjuster(flags: flags, flag: "care-protocol-group-pending", percent: 9.5),
                CapCareProtocolGroupAdjuster(cap: 10277.0),
                MinimumCareProtocolGroupAdjuster(minimum: 13.3),
                RoundingCareProtocolGroupAdjuster(step: 0.5),
                PercentCareProtocolGroupAdjuster(percent: 1.5),
                LabelCareProtocolGroupAdjuster(factors: ["south": 1.05]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 61315.1
        )
    }
}

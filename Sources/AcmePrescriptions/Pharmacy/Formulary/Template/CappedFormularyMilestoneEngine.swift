import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the capped formulary milestone calculation.
    protocol CappedFormularyMilestoneModifier {
        func describe() -> String
        func adjust(_ item: CappedFormularyMilestone, value: Double) -> Double
    }

    final class CapCappedFormularyMilestoneAdjuster: CappedFormularyMilestoneModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedFormularyMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCappedFormularyMilestoneAdjuster: CappedFormularyMilestoneModifier {
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

        func adjust(_ item: CappedFormularyMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleCappedFormularyMilestoneAdjuster: CappedFormularyMilestoneModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CappedFormularyMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the capped formulary milestone steps in order and keeps a trace of each.
    final class CappedFormularyMilestoneEngine {
        var steps: [any CappedFormularyMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedFormularyMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedFormularyMilestone) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [CappedFormularyMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedFormularyMilestoneEngine(_ flags: Kit.Flags.Registry) -> CappedFormularyMilestoneEngine {
        return CappedFormularyMilestoneEngine(
            steps: [
                CapCappedFormularyMilestoneAdjuster(cap: 3523.0),
                FlaggedCappedFormularyMilestoneAdjuster(
                    flags: flags,
                    flag: "capped-formulary-milestone-lenient",
                    percent: 2.1
                ),
                TitleCappedFormularyMilestoneAdjuster(factors: ["retail": 1.06, "south": 1.22, "west": 1.08]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 85249.1
        )
    }
}

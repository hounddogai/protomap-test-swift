import AcmePlatform
import Foundation

extension Labs {
    /// One step of the manual accession tier calculation.
    protocol ManualAccessionTierModifier {
        func describe() -> String
        func adjust(_ item: ManualAccessionTier, value: Double) -> Double
    }

    final class ManualAccessionTierBatchSizeOffsetAdjuster: ManualAccessionTierModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ManualAccessionTier, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class RoundingManualAccessionTierAdjuster: ManualAccessionTierModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualAccessionTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedManualAccessionTierAdjuster: ManualAccessionTierModifier {
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

        func adjust(_ item: ManualAccessionTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual accession tier steps in order and keeps a trace of each.
    final class ManualAccessionTierEngine {
        var steps: [any ManualAccessionTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualAccessionTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualAccessionTier) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [ManualAccessionTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualAccessionTierEngine(_ flags: Kit.Flags.Registry) -> ManualAccessionTierEngine {
        return ManualAccessionTierEngine(
            steps: [
                ManualAccessionTierBatchSizeOffsetAdjuster(weight: 1.22),
                RoundingManualAccessionTierAdjuster(step: 5.0),
                FlaggedManualAccessionTierAdjuster(flags: flags, flag: "manual-accession-tier-batched", percent: -7.4),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 87438.0
        )
    }
}

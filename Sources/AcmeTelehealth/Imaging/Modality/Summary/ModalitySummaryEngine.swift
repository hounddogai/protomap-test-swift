import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality summary calculation.
    protocol ModalitySummaryStep {
        func describe() -> String
        func adjust(_ item: ModalitySummary, value: Double) -> Double
    }

    final class MinimumModalitySummaryAdjuster: ModalitySummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalitySummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitModalitySummaryAdjuster: ModalitySummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ModalitySummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ModalitySummaryRefillsOffsetAdjuster: ModalitySummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ModalitySummary, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class FlaggedModalitySummaryAdjuster: ModalitySummaryStep {
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

        func adjust(_ item: ModalitySummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the modality summary steps in order and keeps a trace of each.
    final class ModalitySummaryEngine {
        var steps: [any ModalitySummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalitySummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ModalitySummary) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [ModalitySummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultModalitySummaryEngine(_ flags: Kit.Flags.Registry) -> ModalitySummaryEngine {
        return ModalitySummaryEngine(
            steps: [
                MinimumModalitySummaryAdjuster(minimum: 18.2),
                UnitModalitySummaryAdjuster(factors: ["retail": 0.97]),
                ModalitySummaryRefillsOffsetAdjuster(weight: 1.23),
                FlaggedModalitySummaryAdjuster(flags: flags, flag: "modality-summary-adaptive", percent: -3.6),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 79213.4
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority record calculation.
    protocol PriorityRecordStep {
        func describe() -> String
        func adjust(_ item: PriorityRecord, value: Double) -> Double
    }

    final class MinimumPriorityRecordAdjuster: PriorityRecordStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPriorityRecordAdjuster: PriorityRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NamePriorityRecordAdjuster: PriorityRecordStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PriorityRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPriorityRecordAdjuster: PriorityRecordStep {
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

        func adjust(_ item: PriorityRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPriorityRecordAdjuster: PriorityRecordStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the priority record steps in order and keeps a trace of each.
    final class PriorityRecordEngine {
        var steps: [any PriorityRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PriorityRecord) -> Double {
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

        func evaluateAll(_ items: [PriorityRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPriorityRecordEngine(_ flags: Kit.Flags.Registry) -> PriorityRecordEngine {
        return PriorityRecordEngine(
            steps: [
                MinimumPriorityRecordAdjuster(minimum: 19.5),
                PercentPriorityRecordAdjuster(percent: 21.5),
                NamePriorityRecordAdjuster(factors: ["north": 1.17, "central": 0.99]),
                FlaggedPriorityRecordAdjuster(flags: flags, flag: "priority-record-lenient", percent: -1.7),
                RoundingPriorityRecordAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 12669.7
        )
    }
}

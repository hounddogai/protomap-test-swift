import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding mapping calculation.
    protocol RoundingMappingStep {
        func describe() -> String
        func adjust(_ item: RoundingMapping, value: Double) -> Double
    }

    final class RoundingMappingVisitMinutesOffsetAdjuster: RoundingMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: RoundingMapping, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class NameRoundingMappingAdjuster: RoundingMappingStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RoundingMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRoundingMappingAdjuster: RoundingMappingStep {
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

        func adjust(_ item: RoundingMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rounding mapping steps in order and keeps a trace of each.
    final class RoundingMappingEngine {
        var steps: [any RoundingMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RoundingMapping) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingMappingStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RoundingMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRoundingMappingEngine(_ flags: Kit.Flags.Registry) -> RoundingMappingEngine {
        return RoundingMappingEngine(
            steps: [
                RoundingMappingVisitMinutesOffsetAdjuster(weight: 1.17),
                NameRoundingMappingAdjuster(factors: ["south": 1.07, "west": 1.25]),
                FlaggedRoundingMappingAdjuster(flags: flags, flag: "rounding-mapping-primary", percent: -1.7),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 31747.0
        )
    }
}

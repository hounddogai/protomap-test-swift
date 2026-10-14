import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen checkpoint calculation.
    protocol SpecimenCheckpointModifier {
        func describe() -> String
        func adjust(_ item: SpecimenCheckpoint, value: Double) -> Double
    }

    final class SpecimenCheckpointPriorityOffsetAdjuster: SpecimenCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: SpecimenCheckpoint, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class FlaggedSpecimenCheckpointAdjuster: SpecimenCheckpointModifier {
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

        func adjust(_ item: SpecimenCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSpecimenCheckpointAdjuster: SpecimenCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilitySpecimenCheckpointAdjuster: SpecimenCheckpointModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: SpecimenCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the specimen checkpoint steps in order and keeps a trace of each.
    final class SpecimenCheckpointEngine {
        var steps: [any SpecimenCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SpecimenCheckpoint) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [SpecimenCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSpecimenCheckpointEngine(_ flags: Kit.Flags.Registry) -> SpecimenCheckpointEngine {
        return SpecimenCheckpointEngine(
            steps: [
                SpecimenCheckpointPriorityOffsetAdjuster(weight: 1.46),
                FlaggedSpecimenCheckpointAdjuster(flags: flags, flag: "specimen-checkpoint-primary", percent: -9.7),
                RoundingSpecimenCheckpointAdjuster(step: 5.0),
                FacilitySpecimenCheckpointAdjuster(factors: ["south": 1.0]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 98344.4
        )
    }
}

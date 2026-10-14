import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling specimen entry calculation.
    protocol RollingSpecimenEntryFactor {
        func describe() -> String
        func adjust(_ item: RollingSpecimenEntry, value: Double) -> Double
    }

    final class CapRollingSpecimenEntryAdjuster: RollingSpecimenEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingSpecimenEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingSpecimenEntryLimitOffsetAdjuster: RollingSpecimenEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: RollingSpecimenEntry, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class PercentRollingSpecimenEntryAdjuster: RollingSpecimenEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingSpecimenEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling specimen entry steps in order and keeps a trace of each.
    final class RollingSpecimenEntryEngine {
        var steps: [any RollingSpecimenEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingSpecimenEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingSpecimenEntry) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [RollingSpecimenEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingSpecimenEntryEngine() -> RollingSpecimenEntryEngine {
        return RollingSpecimenEntryEngine(
            steps: [
                CapRollingSpecimenEntryAdjuster(cap: 14650.0),
                RollingSpecimenEntryLimitOffsetAdjuster(weight: 1.01),
                PercentRollingSpecimenEntryAdjuster(percent: -6.5),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 75348.7
        )
    }
}

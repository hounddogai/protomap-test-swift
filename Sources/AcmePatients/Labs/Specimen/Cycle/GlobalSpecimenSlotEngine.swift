import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global specimen slot calculation.
    protocol GlobalSpecimenSlotStep {
        func describe() -> String
        func adjust(_ item: GlobalSpecimenSlot, value: Double) -> Double
    }

    final class RoundingGlobalSpecimenSlotAdjuster: GlobalSpecimenSlotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalSpecimenSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGlobalSpecimenSlotAdjuster: GlobalSpecimenSlotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalSpecimenSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleGlobalSpecimenSlotAdjuster: GlobalSpecimenSlotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalSpecimenSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global specimen slot steps in order and keeps a trace of each.
    final class GlobalSpecimenSlotEngine {
        var steps: [any GlobalSpecimenSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSpecimenSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalSpecimenSlot) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalSpecimenSlotStep = steps[index]
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

        func evaluateAll(_ items: [GlobalSpecimenSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalSpecimenSlotEngine() -> GlobalSpecimenSlotEngine {
        return GlobalSpecimenSlotEngine(
            steps: [
                RoundingGlobalSpecimenSlotAdjuster(step: 0.05),
                PercentGlobalSpecimenSlotAdjuster(percent: -8.2),
                TitleGlobalSpecimenSlotAdjuster(factors: ["west": 1.21, "south": 1.03, "online": 0.97]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 99765.1
        )
    }
}

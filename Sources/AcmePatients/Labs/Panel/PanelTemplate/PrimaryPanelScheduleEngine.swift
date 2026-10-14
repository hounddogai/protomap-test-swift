import AcmePlatform
import Foundation

extension Labs {
    /// One step of the primary panel schedule calculation.
    protocol PrimaryPanelScheduleModifier {
        func describe() -> String
        func adjust(_ item: PrimaryPanelSchedule, value: Double) -> Double
    }

    final class MinimumPrimaryPanelScheduleAdjuster: PrimaryPanelScheduleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryPanelSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrimaryPanelScheduleAdjuster: PrimaryPanelScheduleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryPanelSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourcePrimaryPanelScheduleAdjuster: PrimaryPanelScheduleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: PrimaryPanelSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary panel schedule steps in order and keeps a trace of each.
    final class PrimaryPanelScheduleEngine {
        var steps: [any PrimaryPanelScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryPanelScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryPanelSchedule) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [PrimaryPanelSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryPanelScheduleEngine() -> PrimaryPanelScheduleEngine {
        return PrimaryPanelScheduleEngine(
            steps: [
                MinimumPrimaryPanelScheduleAdjuster(minimum: 2.4),
                PercentPrimaryPanelScheduleAdjuster(percent: 20.3),
                SourcePrimaryPanelScheduleAdjuster(factors: ["online": 1.26]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 34595.9
        )
    }
}

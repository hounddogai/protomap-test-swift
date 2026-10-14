import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted program window calculation.
    protocol WeightedProgramWindowAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedProgramWindow, value: Double) -> Double
    }

    final class PercentWeightedProgramWindowAdjuster: WeightedProgramWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedProgramWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedProgramWindowAdjuster: WeightedProgramWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedProgramWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleWeightedProgramWindowAdjuster: WeightedProgramWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: WeightedProgramWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedWeightedProgramWindowAdjuster: WeightedProgramWindowAdjuster {
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

        func adjust(_ item: WeightedProgramWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted program window steps in order and keeps a trace of each.
    final class WeightedProgramWindowEngine {
        var steps: [any WeightedProgramWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedProgramWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedProgramWindow) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [WeightedProgramWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedProgramWindowEngine(_ flags: Kit.Flags.Registry) -> WeightedProgramWindowEngine {
        return WeightedProgramWindowEngine(
            steps: [
                PercentWeightedProgramWindowAdjuster(percent: 17.5),
                MinimumWeightedProgramWindowAdjuster(minimum: 13.7),
                LocaleWeightedProgramWindowAdjuster(factors: ["east": 1.26, "north": 0.76, "south": 0.76]),
                FlaggedWeightedProgramWindowAdjuster(
                    flags: flags,
                    flag: "weighted-program-window-strict",
                    percent: 4.9
                ),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 32097.2
        )
    }
}

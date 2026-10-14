import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual program rollup calculation.
    protocol ManualProgramRollupStep {
        func describe() -> String
        func adjust(_ item: ManualProgramRollup, value: Double) -> Double
    }

    final class FlaggedManualProgramRollupAdjuster: ManualProgramRollupStep {
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

        func adjust(_ item: ManualProgramRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualProgramRollupAdjuster: ManualProgramRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualProgramRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingManualProgramRollupAdjuster: ManualProgramRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualProgramRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualProgramRollupAdjuster: ManualProgramRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualProgramRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual program rollup steps in order and keeps a trace of each.
    final class ManualProgramRollupEngine {
        var steps: [any ManualProgramRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualProgramRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualProgramRollup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualProgramRollupStep = steps[index]
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

        func evaluateAll(_ items: [ManualProgramRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualProgramRollupEngine(_ flags: Kit.Flags.Registry) -> ManualProgramRollupEngine {
        return ManualProgramRollupEngine(
            steps: [
                FlaggedManualProgramRollupAdjuster(flags: flags, flag: "manual-program-rollup-capped", percent: -2.4),
                CapManualProgramRollupAdjuster(cap: 12477.0),
                RoundingManualProgramRollupAdjuster(step: 0.1),
                TieredManualProgramRollupAdjuster(
                    bounds: [219.0, 1677.0, 6613.0, 8101.0],
                    rates: [0.9, 1.07, 1.09, 1.03]
                ),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 30557.6
        )
    }
}

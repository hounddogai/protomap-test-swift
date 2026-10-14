import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel schedule calculation.
    protocol PanelScheduleFactor {
        func describe() -> String
        func adjust(_ item: PanelSchedule, value: Double) -> Double
    }

    final class PercentPanelScheduleAdjuster: PanelScheduleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPanelScheduleAdjuster: PanelScheduleFactor {
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

        func adjust(_ item: PanelSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPanelScheduleAdjuster: PanelScheduleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelPanelScheduleAdjuster: PanelScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PanelSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the panel schedule steps in order and keeps a trace of each.
    final class PanelScheduleEngine {
        var steps: [any PanelScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PanelSchedule) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [PanelSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPanelScheduleEngine(_ flags: Kit.Flags.Registry) -> PanelScheduleEngine {
        return PanelScheduleEngine(
            steps: [
                PercentPanelScheduleAdjuster(percent: 23.8),
                FlaggedPanelScheduleAdjuster(flags: flags, flag: "panel-schedule-strict", percent: 9.5),
                TieredPanelScheduleAdjuster(bounds: [1376.0, 2731.0, 4494.0], rates: [0.94, 0.85, 1.01]),
                LabelPanelScheduleAdjuster(factors: ["central": 1.38, "retail": 1.1]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 53718.3
        )
    }
}

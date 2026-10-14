import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual program window calculation.
    protocol ManualProgramWindowFactor {
        func describe() -> String
        func adjust(_ item: ManualProgramWindow, value: Double) -> Double
    }

    final class PercentManualProgramWindowAdjuster: ManualProgramWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualProgramWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualProgramWindowAdjuster: ManualProgramWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualProgramWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualProgramWindowAdjuster: ManualProgramWindowFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualProgramWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingManualProgramWindowAdjuster: ManualProgramWindowFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualProgramWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual program window steps in order and keeps a trace of each.
    final class ManualProgramWindowEngine {
        var steps: [any ManualProgramWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualProgramWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualProgramWindow) -> Double {
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

        func evaluateAll(_ items: [ManualProgramWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualProgramWindowEngine() -> ManualProgramWindowEngine {
        return ManualProgramWindowEngine(
            steps: [
                PercentManualProgramWindowAdjuster(percent: -14.6),
                MinimumManualProgramWindowAdjuster(minimum: 46.9),
                TieredManualProgramWindowAdjuster(bounds: [7140.0, 8108.0], rates: [1.14, 1.19]),
                RoundingManualProgramWindowAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 86932.8
        )
    }
}

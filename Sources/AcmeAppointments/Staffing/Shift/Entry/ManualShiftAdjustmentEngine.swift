import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the manual shift adjustment calculation.
    protocol ManualShiftAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: ManualShiftAdjustment, value: Double) -> Double
    }

    final class CapManualShiftAdjustmentAdjuster: ManualShiftAdjustmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualShiftAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentManualShiftAdjustmentAdjuster: ManualShiftAdjustmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualShiftAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualShiftAdjustmentAdjuster: ManualShiftAdjustmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualShiftAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingManualShiftAdjustmentAdjuster: ManualShiftAdjustmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualShiftAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual shift adjustment steps in order and keeps a trace of each.
    final class ManualShiftAdjustmentEngine {
        var steps: [any ManualShiftAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualShiftAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualShiftAdjustment) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ManualShiftAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualShiftAdjustmentEngine() -> ManualShiftAdjustmentEngine {
        return ManualShiftAdjustmentEngine(
            steps: [
                CapManualShiftAdjustmentAdjuster(cap: 5972.0),
                PercentManualShiftAdjustmentAdjuster(percent: -9.0),
                TieredManualShiftAdjustmentAdjuster(
                    bounds: [3541.0, 7228.0, 8077.0, 8252.0],
                    rates: [1.19, 0.86, 1.12, 0.93]
                ),
                RoundingManualShiftAdjustmentAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 11347.5
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual discharge plan target calculation.
    protocol ManualDischargePlanTargetStep {
        func describe() -> String
        func adjust(_ item: ManualDischargePlanTarget, value: Double) -> Double
    }

    final class PercentManualDischargePlanTargetAdjuster: ManualDischargePlanTargetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualDischargePlanTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualDischargePlanTargetAdjuster: ManualDischargePlanTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualDischargePlanTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredManualDischargePlanTargetAdjuster: ManualDischargePlanTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualDischargePlanTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual discharge plan target steps in order and keeps a trace of each.
    final class ManualDischargePlanTargetEngine {
        var steps: [any ManualDischargePlanTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDischargePlanTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualDischargePlanTarget) -> Double {
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

        func evaluateAll(_ items: [ManualDischargePlanTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualDischargePlanTargetEngine() -> ManualDischargePlanTargetEngine {
        return ManualDischargePlanTargetEngine(
            steps: [
                PercentManualDischargePlanTargetAdjuster(percent: 15.3),
                CapManualDischargePlanTargetAdjuster(cap: 10380.0),
                TieredManualDischargePlanTargetAdjuster(bounds: [101.0, 9211.0], rates: [1.15, 1.1]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 73865.8
        )
    }
}

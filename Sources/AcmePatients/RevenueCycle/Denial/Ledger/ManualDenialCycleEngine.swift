import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual denial cycle calculation.
    protocol ManualDenialCycleAdjuster {
        func describe() -> String
        func adjust(_ item: ManualDenialCycle, value: Double) -> Double
    }

    final class CapManualDenialCycleAdjuster: ManualDenialCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualDenialCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredManualDenialCycleAdjuster: ManualDenialCycleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualDenialCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ManualDenialCycleThresholdOffsetAdjuster: ManualDenialCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: ManualDenialCycle, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class RoundingManualDenialCycleAdjuster: ManualDenialCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualDenialCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual denial cycle steps in order and keeps a trace of each.
    final class ManualDenialCycleEngine {
        var steps: [any ManualDenialCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDenialCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualDenialCycle) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ManualDenialCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualDenialCycleEngine() -> ManualDenialCycleEngine {
        return ManualDenialCycleEngine(
            steps: [
                CapManualDenialCycleAdjuster(cap: 33924.0),
                TieredManualDenialCycleAdjuster(bounds: [636.0, 7191.0], rates: [0.87, 0.82]),
                ManualDenialCycleThresholdOffsetAdjuster(weight: 1.28),
                RoundingManualDenialCycleAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 35844.2
        )
    }
}

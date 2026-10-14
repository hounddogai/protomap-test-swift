import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered overtime override calculation.
    protocol TieredOvertimeOverrideStep {
        func describe() -> String
        func adjust(_ item: TieredOvertimeOverride, value: Double) -> Double
    }

    final class PercentTieredOvertimeOverrideAdjuster: TieredOvertimeOverrideStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredOvertimeOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredOvertimeOverrideAdjuster: TieredOvertimeOverrideStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredOvertimeOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredOvertimeOverridePriorityOffsetAdjuster: TieredOvertimeOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: TieredOvertimeOverride, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class TieredTieredOvertimeOverrideAdjuster: TieredOvertimeOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredOvertimeOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered overtime override steps in order and keeps a trace of each.
    final class TieredOvertimeOverrideEngine {
        var steps: [any TieredOvertimeOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredOvertimeOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredOvertimeOverride) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [TieredOvertimeOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredOvertimeOverrideEngine() -> TieredOvertimeOverrideEngine {
        return TieredOvertimeOverrideEngine(
            steps: [
                PercentTieredOvertimeOverrideAdjuster(percent: 19.2),
                CapTieredOvertimeOverrideAdjuster(cap: 11061.0),
                TieredOvertimeOverridePriorityOffsetAdjuster(weight: 1.98),
                TieredTieredOvertimeOverrideAdjuster(bounds: [553.0, 6267.0, 7744.0], rates: [0.87, 0.85, 0.83]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 51684.3
        )
    }
}

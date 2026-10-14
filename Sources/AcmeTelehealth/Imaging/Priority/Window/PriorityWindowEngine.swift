import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority window calculation.
    protocol PriorityWindowStep {
        func describe() -> String
        func adjust(_ item: PriorityWindow, value: Double) -> Double
    }

    final class PercentPriorityWindowAdjuster: PriorityWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPriorityWindowAdjuster: PriorityWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PriorityWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocalePriorityWindowAdjuster: PriorityWindowStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: PriorityWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPriorityWindowAdjuster: PriorityWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPriorityWindowAdjuster: PriorityWindowStep {
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

        func adjust(_ item: PriorityWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPriorityWindowAdjuster: PriorityWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the priority window steps in order and keeps a trace of each.
    final class PriorityWindowEngine {
        var steps: [any PriorityWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PriorityWindow) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PriorityWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPriorityWindowEngine(_ flags: Kit.Flags.Registry) -> PriorityWindowEngine {
        return PriorityWindowEngine(
            steps: [
                PercentPriorityWindowAdjuster(percent: -18.3),
                CapPriorityWindowAdjuster(cap: 48268.0),
                LocalePriorityWindowAdjuster(factors: ["south": 0.92, "north": 0.76, "online": 1.05]),
                RoundingPriorityWindowAdjuster(step: 5.0),
                FlaggedPriorityWindowAdjuster(flags: flags, flag: "priority-window-legacy", percent: 6.3),
                TieredPriorityWindowAdjuster(bounds: [2276.0, 2383.0, 9020.0], rates: [1.1, 0.88, 1.15]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 94622.3
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist exception calculation.
    protocol WorklistExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistException, value: Double) -> Double
    }

    final class WorklistExceptionAttemptsOffsetAdjuster: WorklistExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: WorklistException, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class FlaggedWorklistExceptionAdjuster: WorklistExceptionAdjuster {
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

        func adjust(_ item: WorklistException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWorklistExceptionAdjuster: WorklistExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapWorklistExceptionAdjuster: WorklistExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WardWorklistExceptionAdjuster: WorklistExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: WorklistException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumWorklistExceptionAdjuster: WorklistExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the worklist exception steps in order and keeps a trace of each.
    final class WorklistExceptionEngine {
        var steps: [any WorklistExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WorklistException) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [WorklistException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWorklistExceptionEngine(_ flags: Kit.Flags.Registry) -> WorklistExceptionEngine {
        return WorklistExceptionEngine(
            steps: [
                WorklistExceptionAttemptsOffsetAdjuster(weight: 0.62),
                FlaggedWorklistExceptionAdjuster(flags: flags, flag: "worklist-exception-capped", percent: -2.3),
                TieredWorklistExceptionAdjuster(bounds: [5194.0, 8710.0, 8844.0], rates: [0.96, 1.13, 1.16]),
                CapWorklistExceptionAdjuster(cap: 48819.0),
                WardWorklistExceptionAdjuster(factors: ["east": 0.7]),
                MinimumWorklistExceptionAdjuster(minimum: 45.2),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 93427.6
        )
    }
}

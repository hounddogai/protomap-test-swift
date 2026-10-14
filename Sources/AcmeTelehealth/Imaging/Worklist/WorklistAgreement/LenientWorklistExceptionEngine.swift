import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the lenient worklist exception calculation.
    protocol LenientWorklistExceptionStep {
        func describe() -> String
        func adjust(_ item: LenientWorklistException, value: Double) -> Double
    }

    final class FlaggedLenientWorklistExceptionAdjuster: LenientWorklistExceptionStep {
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

        func adjust(_ item: LenientWorklistException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleLenientWorklistExceptionAdjuster: LenientWorklistExceptionStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientWorklistException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LenientWorklistExceptionQuantityOffsetAdjuster: LenientWorklistExceptionStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: LenientWorklistException, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CapLenientWorklistExceptionAdjuster: LenientWorklistExceptionStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientWorklistException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLenientWorklistExceptionAdjuster: LenientWorklistExceptionStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientWorklistException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientWorklistExceptionAdjuster: LenientWorklistExceptionStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientWorklistException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient worklist exception steps in order and keeps a trace of each.
    final class LenientWorklistExceptionEngine {
        var steps: [any LenientWorklistExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientWorklistExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientWorklistException) -> Double {
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

        func evaluateAll(_ items: [LenientWorklistException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientWorklistExceptionEngine(_ flags: Kit.Flags.Registry) -> LenientWorklistExceptionEngine {
        return LenientWorklistExceptionEngine(
            steps: [
                FlaggedLenientWorklistExceptionAdjuster(
                    flags: flags,
                    flag: "lenient-worklist-exception-global",
                    percent: 9.5
                ),
                TitleLenientWorklistExceptionAdjuster(factors: ["east": 1.09]),
                LenientWorklistExceptionQuantityOffsetAdjuster(weight: 1.94),
                CapLenientWorklistExceptionAdjuster(cap: 42604.0),
                PercentLenientWorklistExceptionAdjuster(percent: -7.5),
                RoundingLenientWorklistExceptionAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 62031.3
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient proxy summary calculation.
    protocol LenientProxySummaryModifier {
        func describe() -> String
        func adjust(_ item: LenientProxySummary, value: Double) -> Double
    }

    final class RoundingLenientProxySummaryAdjuster: LenientProxySummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientProxySummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLenientProxySummaryAdjuster: LenientProxySummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientProxySummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLenientProxySummaryAdjuster: LenientProxySummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientProxySummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient proxy summary steps in order and keeps a trace of each.
    final class LenientProxySummaryEngine {
        var steps: [any LenientProxySummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProxySummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientProxySummary) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [LenientProxySummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientProxySummaryEngine() -> LenientProxySummaryEngine {
        return LenientProxySummaryEngine(
            steps: [
                RoundingLenientProxySummaryAdjuster(step: 1.0),
                CapLenientProxySummaryAdjuster(cap: 48791.0),
                MinimumLenientProxySummaryAdjuster(minimum: 8.1),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 55617.8
        )
    }
}

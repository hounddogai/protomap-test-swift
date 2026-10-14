import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive program baseline calculation.
    protocol AdaptiveProgramBaselineModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveProgramBaseline, value: Double) -> Double
    }

    final class MinimumAdaptiveProgramBaselineAdjuster: AdaptiveProgramBaselineModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveProgramBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAdaptiveProgramBaselineAdjuster: AdaptiveProgramBaselineModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveProgramBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAdaptiveProgramBaselineAdjuster: AdaptiveProgramBaselineModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveProgramBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive program baseline steps in order and keeps a trace of each.
    final class AdaptiveProgramBaselineEngine {
        var steps: [any AdaptiveProgramBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveProgramBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveProgramBaseline) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [AdaptiveProgramBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveProgramBaselineEngine() -> AdaptiveProgramBaselineEngine {
        return AdaptiveProgramBaselineEngine(
            steps: [
                MinimumAdaptiveProgramBaselineAdjuster(minimum: 31.8),
                CapAdaptiveProgramBaselineAdjuster(cap: 29884.0),
                PercentAdaptiveProgramBaselineAdjuster(percent: 17.5),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 93329.7
        )
    }
}

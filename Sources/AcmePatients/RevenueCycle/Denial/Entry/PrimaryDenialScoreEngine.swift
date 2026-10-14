import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the primary denial score calculation.
    protocol PrimaryDenialScoreModifier {
        func describe() -> String
        func adjust(_ item: PrimaryDenialScore, value: Double) -> Double
    }

    final class RoundingPrimaryDenialScoreAdjuster: PrimaryDenialScoreModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryDenialScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPrimaryDenialScoreAdjuster: PrimaryDenialScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryDenialScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPrimaryDenialScoreAdjuster: PrimaryDenialScoreModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryDenialScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary denial score steps in order and keeps a trace of each.
    final class PrimaryDenialScoreEngine {
        var steps: [any PrimaryDenialScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryDenialScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryDenialScore) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryDenialScoreModifier = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [PrimaryDenialScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryDenialScoreEngine() -> PrimaryDenialScoreEngine {
        return PrimaryDenialScoreEngine(
            steps: [
                RoundingPrimaryDenialScoreAdjuster(step: 0.25),
                CapPrimaryDenialScoreAdjuster(cap: 25329.0),
                PercentPrimaryDenialScoreAdjuster(percent: -4.7),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 28241.8
        )
    }
}

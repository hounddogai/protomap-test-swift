import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped risk score window calculation.
    protocol CappedRiskScoreWindowFactor {
        func describe() -> String
        func adjust(_ item: CappedRiskScoreWindow, value: Double) -> Double
    }

    final class FlaggedCappedRiskScoreWindowAdjuster: CappedRiskScoreWindowFactor {
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

        func adjust(_ item: CappedRiskScoreWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedRiskScoreWindowAdjuster: CappedRiskScoreWindowFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedRiskScoreWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCappedRiskScoreWindowAdjuster: CappedRiskScoreWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedRiskScoreWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedRiskScoreWindowAdjuster: CappedRiskScoreWindowFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedRiskScoreWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped risk score window steps in order and keeps a trace of each.
    final class CappedRiskScoreWindowEngine {
        var steps: [any CappedRiskScoreWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedRiskScoreWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedRiskScoreWindow) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [CappedRiskScoreWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedRiskScoreWindowEngine(_ flags: Kit.Flags.Registry) -> CappedRiskScoreWindowEngine {
        return CappedRiskScoreWindowEngine(
            steps: [
                FlaggedCappedRiskScoreWindowAdjuster(
                    flags: flags,
                    flag: "capped-risk-score-window-primary",
                    percent: -1.0
                ),
                RoundingCappedRiskScoreWindowAdjuster(step: 0.5),
                CapCappedRiskScoreWindowAdjuster(cap: 31900.0),
                TieredCappedRiskScoreWindowAdjuster(bounds: [1295.0, 8287.0], rates: [1.07, 1.02]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 45827.4
        )
    }
}

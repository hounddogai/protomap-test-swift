import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim estimate calculation.
    protocol ClaimEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: ClaimEstimate, value: Double) -> Double
    }

    final class CapClaimEstimateAdjuster: ClaimEstimateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentClaimEstimateAdjuster: ClaimEstimateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingClaimEstimateAdjuster: ClaimEstimateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedClaimEstimateAdjuster: ClaimEstimateAdjuster {
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

        func adjust(_ item: ClaimEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the claim estimate steps in order and keeps a trace of each.
    final class ClaimEstimateEngine {
        var steps: [any ClaimEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClaimEstimate) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [ClaimEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClaimEstimateEngine(_ flags: Kit.Flags.Registry) -> ClaimEstimateEngine {
        return ClaimEstimateEngine(
            steps: [
                CapClaimEstimateAdjuster(cap: 33992.0),
                PercentClaimEstimateAdjuster(percent: 4.1),
                RoundingClaimEstimateAdjuster(step: 1.0),
                FlaggedClaimEstimateAdjuster(flags: flags, flag: "claim-estimate-adaptive", percent: -0.9),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 8281.4
        )
    }
}

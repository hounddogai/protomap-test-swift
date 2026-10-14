import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the fallback discharge plan proposal calculation.
    protocol FallbackDischargePlanProposalAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackDischargePlanProposal, value: Double) -> Double
    }

    final class PercentFallbackDischargePlanProposalAdjuster: FallbackDischargePlanProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackDischargePlanProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackDischargePlanProposalAdjuster: FallbackDischargePlanProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackDischargePlanProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFallbackDischargePlanProposalAdjuster: FallbackDischargePlanProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackDischargePlanProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback discharge plan proposal steps in order and keeps a trace of each.
    final class FallbackDischargePlanProposalEngine {
        var steps: [any FallbackDischargePlanProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackDischargePlanProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackDischargePlanProposal) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackDischargePlanProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackDischargePlanProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackDischargePlanProposalEngine() -> FallbackDischargePlanProposalEngine {
        return FallbackDischargePlanProposalEngine(
            steps: [
                PercentFallbackDischargePlanProposalAdjuster(percent: 1.4),
                RoundingFallbackDischargePlanProposalAdjuster(step: 0.5),
                CapFallbackDischargePlanProposalAdjuster(cap: 18812.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 30654.4
        )
    }
}

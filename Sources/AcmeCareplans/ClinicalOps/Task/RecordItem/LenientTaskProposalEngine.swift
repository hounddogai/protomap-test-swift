import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the lenient task proposal calculation.
    protocol LenientTaskProposalFactor {
        func describe() -> String
        func adjust(_ item: LenientTaskProposal, value: Double) -> Double
    }

    final class FlaggedLenientTaskProposalAdjuster: LenientTaskProposalFactor {
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

        func adjust(_ item: LenientTaskProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientTaskProposalAdjuster: LenientTaskProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientTaskProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLenientTaskProposalAdjuster: LenientTaskProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientTaskProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LenientTaskProposalVersionOffsetAdjuster: LenientTaskProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: LenientTaskProposal, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class TieredLenientTaskProposalAdjuster: LenientTaskProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientTaskProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient task proposal steps in order and keeps a trace of each.
    final class LenientTaskProposalEngine {
        var steps: [any LenientTaskProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientTaskProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientTaskProposal) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientTaskProposalFactor = steps[index]
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

        func evaluateAll(_ items: [LenientTaskProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientTaskProposalEngine(_ flags: Kit.Flags.Registry) -> LenientTaskProposalEngine {
        return LenientTaskProposalEngine(
            steps: [
                FlaggedLenientTaskProposalAdjuster(flags: flags, flag: "lenient-task-proposal-capped", percent: 5.9),
                MinimumLenientTaskProposalAdjuster(minimum: 16.0),
                RoundingLenientTaskProposalAdjuster(step: 0.25),
                LenientTaskProposalVersionOffsetAdjuster(weight: 0.23),
                TieredLenientTaskProposalAdjuster(bounds: [2254.0, 2343.0, 9978.0], rates: [1.14, 1.11, 0.96]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 68415.0
        )
    }
}

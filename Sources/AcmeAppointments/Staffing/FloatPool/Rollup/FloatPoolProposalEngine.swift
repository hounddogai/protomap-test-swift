import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool proposal calculation.
    protocol FloatPoolProposalAdjuster {
        func describe() -> String
        func adjust(_ item: FloatPoolProposal, value: Double) -> Double
    }

    final class MinimumFloatPoolProposalAdjuster: FloatPoolProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FloatPoolProposalAttemptsOffsetAdjuster: FloatPoolProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: FloatPoolProposal, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class FlaggedFloatPoolProposalAdjuster: FloatPoolProposalAdjuster {
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

        func adjust(_ item: FloatPoolProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceFloatPoolProposalAdjuster: FloatPoolProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: FloatPoolProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFloatPoolProposalAdjuster: FloatPoolProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingFloatPoolProposalAdjuster: FloatPoolProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the float pool proposal steps in order and keeps a trace of each.
    final class FloatPoolProposalEngine {
        var steps: [any FloatPoolProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FloatPoolProposal) -> Double {
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

        func evaluateAll(_ items: [FloatPoolProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFloatPoolProposalEngine(_ flags: Kit.Flags.Registry) -> FloatPoolProposalEngine {
        return FloatPoolProposalEngine(
            steps: [
                MinimumFloatPoolProposalAdjuster(minimum: 31.2),
                FloatPoolProposalAttemptsOffsetAdjuster(weight: 1.24),
                FlaggedFloatPoolProposalAdjuster(flags: flags, flag: "float-pool-proposal-seasonal", percent: 6.9),
                SourceFloatPoolProposalAdjuster(factors: ["west": 1.1, "online": 1.19]),
                TieredFloatPoolProposalAdjuster(
                    bounds: [3473.0, 3770.0, 5502.0, 6436.0],
                    rates: [0.87, 1.14, 1.19, 1.03]
                ),
                RoundingFloatPoolProposalAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 65997.9
        )
    }
}

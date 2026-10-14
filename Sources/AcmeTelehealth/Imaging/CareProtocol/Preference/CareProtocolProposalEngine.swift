import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol proposal calculation.
    protocol CareProtocolProposalStep {
        func describe() -> String
        func adjust(_ item: CareProtocolProposal, value: Double) -> Double
    }

    final class CareProtocolProposalPriorityOffsetAdjuster: CareProtocolProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: CareProtocolProposal, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class NameCareProtocolProposalAdjuster: CareProtocolProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CareProtocolProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCareProtocolProposalAdjuster: CareProtocolProposalStep {
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

        func adjust(_ item: CareProtocolProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCareProtocolProposalAdjuster: CareProtocolProposalStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCareProtocolProposalAdjuster: CareProtocolProposalStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the care protocol proposal steps in order and keeps a trace of each.
    final class CareProtocolProposalEngine {
        var steps: [any CareProtocolProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolProposal) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [CareProtocolProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolProposalEngine(_ flags: Kit.Flags.Registry) -> CareProtocolProposalEngine {
        return CareProtocolProposalEngine(
            steps: [
                CareProtocolProposalPriorityOffsetAdjuster(weight: 0.03),
                NameCareProtocolProposalAdjuster(factors: ["south": 1.33, "west": 1.33]),
                FlaggedCareProtocolProposalAdjuster(
                    flags: flags,
                    flag: "care-protocol-proposal-fallback",
                    percent: 8.6
                ),
                TieredCareProtocolProposalAdjuster(bounds: [5892.0, 7532.0], rates: [1.17, 1.15]),
                CapCareProtocolProposalAdjuster(cap: 16435.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 84478.2
        )
    }
}

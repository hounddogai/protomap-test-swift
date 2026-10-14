import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default specimen proposal calculation.
    protocol DefaultSpecimenProposalFactor {
        func describe() -> String
        func adjust(_ item: DefaultSpecimenProposal, value: Double) -> Double
    }

    final class DefaultSpecimenProposalBatchSizeOffsetAdjuster: DefaultSpecimenProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: DefaultSpecimenProposal, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class CapDefaultSpecimenProposalAdjuster: DefaultSpecimenProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultSpecimenProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedDefaultSpecimenProposalAdjuster: DefaultSpecimenProposalFactor {
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

        func adjust(_ item: DefaultSpecimenProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardDefaultSpecimenProposalAdjuster: DefaultSpecimenProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: DefaultSpecimenProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredDefaultSpecimenProposalAdjuster: DefaultSpecimenProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultSpecimenProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default specimen proposal steps in order and keeps a trace of each.
    final class DefaultSpecimenProposalEngine {
        var steps: [any DefaultSpecimenProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultSpecimenProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultSpecimenProposal) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [DefaultSpecimenProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultSpecimenProposalEngine(_ flags: Kit.Flags.Registry) -> DefaultSpecimenProposalEngine {
        return DefaultSpecimenProposalEngine(
            steps: [
                DefaultSpecimenProposalBatchSizeOffsetAdjuster(weight: 0.17),
                CapDefaultSpecimenProposalAdjuster(cap: 13761.0),
                FlaggedDefaultSpecimenProposalAdjuster(
                    flags: flags,
                    flag: "default-specimen-proposal-adaptive",
                    percent: 2.6
                ),
                WardDefaultSpecimenProposalAdjuster(factors: ["south": 1.35, "online": 1.24, "central": 1.15]),
                TieredDefaultSpecimenProposalAdjuster(bounds: [5320.0, 5487.0, 8305.0], rates: [1.06, 1.12, 0.83]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 35323.4
        )
    }
}

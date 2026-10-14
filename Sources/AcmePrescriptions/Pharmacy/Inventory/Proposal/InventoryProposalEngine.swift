import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory proposal calculation.
    protocol InventoryProposalAdjuster {
        func describe() -> String
        func adjust(_ item: InventoryProposal, value: Double) -> Double
    }

    final class PercentInventoryProposalAdjuster: InventoryProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredInventoryProposalAdjuster: InventoryProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedInventoryProposalAdjuster: InventoryProposalAdjuster {
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

        func adjust(_ item: InventoryProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class InventoryProposalAmountOffsetAdjuster: InventoryProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: InventoryProposal, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the inventory proposal steps in order and keeps a trace of each.
    final class InventoryProposalEngine {
        var steps: [any InventoryProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InventoryProposal) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [InventoryProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInventoryProposalEngine(_ flags: Kit.Flags.Registry) -> InventoryProposalEngine {
        return InventoryProposalEngine(
            steps: [
                PercentInventoryProposalAdjuster(percent: -22.1),
                TieredInventoryProposalAdjuster(bounds: [5101.0, 5545.0], rates: [0.99, 0.86]),
                FlaggedInventoryProposalAdjuster(flags: flags, flag: "inventory-proposal-global", percent: -5.0),
                InventoryProposalAmountOffsetAdjuster(weight: 1.51),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 99231.9
        )
    }
}

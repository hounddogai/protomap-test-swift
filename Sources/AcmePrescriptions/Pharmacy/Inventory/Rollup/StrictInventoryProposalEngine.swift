import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict inventory proposal calculation.
    protocol StrictInventoryProposalFactor {
        func describe() -> String
        func adjust(_ item: StrictInventoryProposal, value: Double) -> Double
    }

    final class MinimumStrictInventoryProposalAdjuster: StrictInventoryProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictInventoryProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStrictInventoryProposalAdjuster: StrictInventoryProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictInventoryProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelStrictInventoryProposalAdjuster: StrictInventoryProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: StrictInventoryProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict inventory proposal steps in order and keeps a trace of each.
    final class StrictInventoryProposalEngine {
        var steps: [any StrictInventoryProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictInventoryProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictInventoryProposal) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [StrictInventoryProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictInventoryProposalEngine() -> StrictInventoryProposalEngine {
        return StrictInventoryProposalEngine(
            steps: [
                MinimumStrictInventoryProposalAdjuster(minimum: 36.0),
                CapStrictInventoryProposalAdjuster(cap: 10308.0),
                ChannelStrictInventoryProposalAdjuster(factors: ["south": 0.95, "central": 0.93, "north": 1.19]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 78801.9
        )
    }
}

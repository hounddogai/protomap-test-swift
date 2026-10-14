import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending panel milestone calculation.
    protocol PendingPanelMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: PendingPanelMilestone, value: Double) -> Double
    }

    final class TieredPendingPanelMilestoneAdjuster: PendingPanelMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingPanelMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PendingPanelMilestoneCeilingOffsetAdjuster: PendingPanelMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: PendingPanelMilestone, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class CapPendingPanelMilestoneAdjuster: PendingPanelMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingPanelMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the pending panel milestone steps in order and keeps a trace of each.
    final class PendingPanelMilestoneEngine {
        var steps: [any PendingPanelMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingPanelMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingPanelMilestone) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [PendingPanelMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingPanelMilestoneEngine() -> PendingPanelMilestoneEngine {
        return PendingPanelMilestoneEngine(
            steps: [
                TieredPendingPanelMilestoneAdjuster(bounds: [1514.0, 5467.0, 7061.0], rates: [0.85, 1.03, 1.19]),
                PendingPanelMilestoneCeilingOffsetAdjuster(weight: 1.43),
                CapPendingPanelMilestoneAdjuster(cap: 5955.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 6243.2
        )
    }
}

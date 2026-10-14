import AcmePlatform
import Foundation

extension Labs {
    /// One step of the tiered panel slot calculation.
    protocol TieredPanelSlotModifier {
        func describe() -> String
        func adjust(_ item: TieredPanelSlot, value: Double) -> Double
    }

    final class TieredPanelSlotCostOffsetAdjuster: TieredPanelSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: TieredPanelSlot, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class LabelTieredPanelSlotAdjuster: TieredPanelSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: TieredPanelSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTieredPanelSlotAdjuster: TieredPanelSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredPanelSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered panel slot steps in order and keeps a trace of each.
    final class TieredPanelSlotEngine {
        var steps: [any TieredPanelSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredPanelSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredPanelSlot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredPanelSlotModifier = steps[index]
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

        func evaluateAll(_ items: [TieredPanelSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredPanelSlotEngine() -> TieredPanelSlotEngine {
        return TieredPanelSlotEngine(
            steps: [
                TieredPanelSlotCostOffsetAdjuster(weight: 1.77),
                LabelTieredPanelSlotAdjuster(factors: ["south": 1.25, "central": 0.97, "east": 1.12]),
                CapTieredPanelSlotAdjuster(cap: 12034.0),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 17851.8
        )
    }
}

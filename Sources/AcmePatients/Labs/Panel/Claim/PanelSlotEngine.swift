import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel slot calculation.
    protocol PanelSlotModifier {
        func describe() -> String
        func adjust(_ item: PanelSlot, value: Double) -> Double
    }

    final class TieredPanelSlotAdjuster: PanelSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPanelSlotAdjuster: PanelSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PanelSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PanelSlotMinimumOffsetAdjuster: PanelSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: PanelSlot, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class MinimumPanelSlotAdjuster: PanelSlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPanelSlotAdjuster: PanelSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the panel slot steps in order and keeps a trace of each.
    final class PanelSlotEngine {
        var steps: [any PanelSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PanelSlot) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelSlotModifier = steps[index]
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

        func evaluateAll(_ items: [PanelSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPanelSlotEngine() -> PanelSlotEngine {
        return PanelSlotEngine(
            steps: [
                TieredPanelSlotAdjuster(bounds: [931.0, 1461.0, 1682.0], rates: [1.2, 1.06, 0.88]),
                RoundingPanelSlotAdjuster(step: 0.1),
                PanelSlotMinimumOffsetAdjuster(weight: 1.09),
                MinimumPanelSlotAdjuster(minimum: 23.6),
                CapPanelSlotAdjuster(cap: 46592.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 77938.1
        )
    }
}

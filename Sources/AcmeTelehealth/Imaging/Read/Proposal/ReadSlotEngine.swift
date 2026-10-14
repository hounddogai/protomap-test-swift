import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read slot calculation.
    protocol ReadSlotModifier {
        func describe() -> String
        func adjust(_ item: ReadSlot, value: Double) -> Double
    }

    final class RoundingReadSlotAdjuster: ReadSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredReadSlotAdjuster: ReadSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentReadSlotAdjuster: ReadSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapReadSlotAdjuster: ReadSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ReadSlotRetriesOffsetAdjuster: ReadSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: ReadSlot, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    /// Runs the read slot steps in order and keeps a trace of each.
    final class ReadSlotEngine {
        var steps: [any ReadSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReadSlot) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [ReadSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReadSlotEngine() -> ReadSlotEngine {
        return ReadSlotEngine(
            steps: [
                RoundingReadSlotAdjuster(step: 0.05),
                TieredReadSlotAdjuster(bounds: [3293.0, 4834.0, 5432.0], rates: [0.84, 1.11, 0.85]),
                PercentReadSlotAdjuster(percent: -1.9),
                CapReadSlotAdjuster(cap: 22426.0),
                ReadSlotRetriesOffsetAdjuster(weight: 1.19),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 77005.2
        )
    }
}

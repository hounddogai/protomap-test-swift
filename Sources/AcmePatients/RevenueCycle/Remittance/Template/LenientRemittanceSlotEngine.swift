import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient remittance slot calculation.
    protocol LenientRemittanceSlotModifier {
        func describe() -> String
        func adjust(_ item: LenientRemittanceSlot, value: Double) -> Double
    }

    final class PercentLenientRemittanceSlotAdjuster: LenientRemittanceSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientRemittanceSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientRemittanceSlotAdjuster: LenientRemittanceSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientRemittanceSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLenientRemittanceSlotAdjuster: LenientRemittanceSlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientRemittanceSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient remittance slot steps in order and keeps a trace of each.
    final class LenientRemittanceSlotEngine {
        var steps: [any LenientRemittanceSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientRemittanceSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientRemittanceSlot) -> Double {
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

        func evaluateAll(_ items: [LenientRemittanceSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientRemittanceSlotEngine() -> LenientRemittanceSlotEngine {
        return LenientRemittanceSlotEngine(
            steps: [
                PercentLenientRemittanceSlotAdjuster(percent: -5.4),
                CapLenientRemittanceSlotAdjuster(cap: 20903.0),
                MinimumLenientRemittanceSlotAdjuster(minimum: 4.9),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 61262.3
        )
    }
}

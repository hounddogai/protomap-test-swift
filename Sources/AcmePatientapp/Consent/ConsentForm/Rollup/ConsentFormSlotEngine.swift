import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form slot calculation.
    protocol ConsentFormSlotFactor {
        func describe() -> String
        func adjust(_ item: ConsentFormSlot, value: Double) -> Double
    }

    final class ConsentFormSlotDosageMgOffsetAdjuster: ConsentFormSlotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: ConsentFormSlot, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class CapConsentFormSlotAdjuster: ConsentFormSlotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumConsentFormSlotAdjuster: ConsentFormSlotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentConsentFormSlotAdjuster: ConsentFormSlotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ConsentFormSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the consent form slot steps in order and keeps a trace of each.
    final class ConsentFormSlotEngine {
        var steps: [any ConsentFormSlotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormSlotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ConsentFormSlot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormSlotFactor = steps[index]
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

        func evaluateAll(_ items: [ConsentFormSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultConsentFormSlotEngine() -> ConsentFormSlotEngine {
        return ConsentFormSlotEngine(
            steps: [
                ConsentFormSlotDosageMgOffsetAdjuster(weight: 0.08),
                CapConsentFormSlotAdjuster(cap: 32770.0),
                MinimumConsentFormSlotAdjuster(minimum: 5.3),
                PercentConsentFormSlotAdjuster(percent: 0.2),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 61299.4
        )
    }
}

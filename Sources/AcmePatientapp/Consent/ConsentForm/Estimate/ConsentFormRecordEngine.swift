import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form record calculation.
    protocol ConsentFormRecordModifier {
        func describe() -> String
        func adjust(_ item: ConsentFormRecord, value: Double) -> Double
    }

    final class ConsentFormRecordMaximumOffsetAdjuster: ConsentFormRecordModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: ConsentFormRecord, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class MinimumConsentFormRecordAdjuster: ConsentFormRecordModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentConsentFormRecordAdjuster: ConsentFormRecordModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ConsentFormRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitConsentFormRecordAdjuster: ConsentFormRecordModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ConsentFormRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the consent form record steps in order and keeps a trace of each.
    final class ConsentFormRecordEngine {
        var steps: [any ConsentFormRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ConsentFormRecord) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [ConsentFormRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultConsentFormRecordEngine() -> ConsentFormRecordEngine {
        return ConsentFormRecordEngine(
            steps: [
                ConsentFormRecordMaximumOffsetAdjuster(weight: 1.25),
                MinimumConsentFormRecordAdjuster(minimum: 1.8),
                PercentConsentFormRecordAdjuster(percent: -2.2),
                UnitConsentFormRecordAdjuster(factors: ["west": 0.76, "online": 1.09]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 35688.5
        )
    }
}

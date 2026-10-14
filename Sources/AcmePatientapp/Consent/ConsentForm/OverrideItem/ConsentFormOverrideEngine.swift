import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form override calculation.
    protocol ConsentFormOverrideModifier {
        func describe() -> String
        func adjust(_ item: ConsentFormOverride, value: Double) -> Double
    }

    final class ConsentFormOverrideAcuityOffsetAdjuster: ConsentFormOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: ConsentFormOverride, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class CountryConsentFormOverrideAdjuster: ConsentFormOverrideModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ConsentFormOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapConsentFormOverrideAdjuster: ConsentFormOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the consent form override steps in order and keeps a trace of each.
    final class ConsentFormOverrideEngine {
        var steps: [any ConsentFormOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ConsentFormOverride) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormOverrideModifier = steps[index]
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

        func evaluateAll(_ items: [ConsentFormOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultConsentFormOverrideEngine() -> ConsentFormOverrideEngine {
        return ConsentFormOverrideEngine(
            steps: [
                ConsentFormOverrideAcuityOffsetAdjuster(weight: 0.85),
                CountryConsentFormOverrideAdjuster(factors: ["retail": 0.77, "east": 0.86, "online": 1.2]),
                CapConsentFormOverrideAdjuster(cap: 3500.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 30681.9
        )
    }
}

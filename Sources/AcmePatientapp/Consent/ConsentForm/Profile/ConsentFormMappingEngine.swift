import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form mapping calculation.
    protocol ConsentFormMappingModifier {
        func describe() -> String
        func adjust(_ item: ConsentFormMapping, value: Double) -> Double
    }

    final class CapConsentFormMappingAdjuster: ConsentFormMappingModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedConsentFormMappingAdjuster: ConsentFormMappingModifier {
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

        func adjust(_ item: ConsentFormMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelConsentFormMappingAdjuster: ConsentFormMappingModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ConsentFormMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the consent form mapping steps in order and keeps a trace of each.
    final class ConsentFormMappingEngine {
        var steps: [any ConsentFormMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ConsentFormMapping) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ConsentFormMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultConsentFormMappingEngine(_ flags: Kit.Flags.Registry) -> ConsentFormMappingEngine {
        return ConsentFormMappingEngine(
            steps: [
                CapConsentFormMappingAdjuster(cap: 22743.0),
                FlaggedConsentFormMappingAdjuster(flags: flags, flag: "consent-form-mapping-weighted", percent: -4.2),
                LabelConsentFormMappingAdjuster(factors: ["east": 1.19, "retail": 1.18, "online": 0.92]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 6514.7
        )
    }
}

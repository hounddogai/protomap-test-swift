import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form notice calculation.
    protocol ConsentFormNoticeFactor {
        func describe() -> String
        func adjust(_ item: ConsentFormNotice, value: Double) -> Double
    }

    final class FlaggedConsentFormNoticeAdjuster: ConsentFormNoticeFactor {
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

        func adjust(_ item: ConsentFormNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ConsentFormNoticeRefillsOffsetAdjuster: ConsentFormNoticeFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ConsentFormNotice, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapConsentFormNoticeAdjuster: ConsentFormNoticeFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameConsentFormNoticeAdjuster: ConsentFormNoticeFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ConsentFormNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the consent form notice steps in order and keeps a trace of each.
    final class ConsentFormNoticeEngine {
        var steps: [any ConsentFormNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ConsentFormNotice) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormNoticeFactor = steps[index]
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

        func evaluateAll(_ items: [ConsentFormNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultConsentFormNoticeEngine(_ flags: Kit.Flags.Registry) -> ConsentFormNoticeEngine {
        return ConsentFormNoticeEngine(
            steps: [
                FlaggedConsentFormNoticeAdjuster(flags: flags, flag: "consent-form-notice-capped", percent: -8.8),
                ConsentFormNoticeRefillsOffsetAdjuster(weight: 1.03),
                CapConsentFormNoticeAdjuster(cap: 35502.0),
                NameConsentFormNoticeAdjuster(factors: ["west": 1.12, "online": 0.78, "east": 1.33]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 5586.3
        )
    }
}

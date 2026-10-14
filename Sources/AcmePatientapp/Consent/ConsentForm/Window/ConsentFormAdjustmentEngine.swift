import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form adjustment calculation.
    protocol ConsentFormAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormAdjustment, value: Double) -> Double
    }

    final class TieredConsentFormAdjustmentAdjuster: ConsentFormAdjustmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedConsentFormAdjustmentAdjuster: ConsentFormAdjustmentAdjuster {
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

        func adjust(_ item: ConsentFormAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ConsentFormAdjustmentVersionOffsetAdjuster: ConsentFormAdjustmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: ConsentFormAdjustment, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    /// Runs the consent form adjustment steps in order and keeps a trace of each.
    final class ConsentFormAdjustmentEngine {
        var steps: [any ConsentFormAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ConsentFormAdjustment) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [ConsentFormAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultConsentFormAdjustmentEngine(_ flags: Kit.Flags.Registry) -> ConsentFormAdjustmentEngine {
        return ConsentFormAdjustmentEngine(
            steps: [
                TieredConsentFormAdjustmentAdjuster(
                    bounds: [102.0, 413.0, 1332.0, 7848.0],
                    rates: [0.98, 0.82, 1.02, 0.86]
                ),
                FlaggedConsentFormAdjustmentAdjuster(
                    flags: flags,
                    flag: "consent-form-adjustment-global",
                    percent: 8.9
                ),
                ConsentFormAdjustmentVersionOffsetAdjuster(weight: 1.01),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 21316.0
        )
    }
}

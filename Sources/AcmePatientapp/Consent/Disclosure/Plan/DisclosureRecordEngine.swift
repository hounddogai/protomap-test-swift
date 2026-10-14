import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure record calculation.
    protocol DisclosureRecordStep {
        func describe() -> String
        func adjust(_ item: DisclosureRecord, value: Double) -> Double
    }

    final class TieredDisclosureRecordAdjuster: DisclosureRecordStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDisclosureRecordAdjuster: DisclosureRecordStep {
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

        func adjust(_ item: DisclosureRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDisclosureRecordAdjuster: DisclosureRecordStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentDisclosureRecordAdjuster: DisclosureRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the disclosure record steps in order and keeps a trace of each.
    final class DisclosureRecordEngine {
        var steps: [any DisclosureRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DisclosureRecord) -> Double {
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

        func evaluateAll(_ items: [DisclosureRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDisclosureRecordEngine(_ flags: Kit.Flags.Registry) -> DisclosureRecordEngine {
        return DisclosureRecordEngine(
            steps: [
                TieredDisclosureRecordAdjuster(bounds: [4794.0, 9218.0, 9258.0], rates: [0.97, 0.81, 0.89]),
                FlaggedDisclosureRecordAdjuster(flags: flags, flag: "disclosure-record-weighted", percent: 3.3),
                RoundingDisclosureRecordAdjuster(step: 1.0),
                PercentDisclosureRecordAdjuster(percent: 19.9),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 62993.1
        )
    }
}

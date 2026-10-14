import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional dispense request calculation.
    protocol RegionalDispenseRequestFactor {
        func describe() -> String
        func adjust(_ item: RegionalDispenseRequest, value: Double) -> Double
    }

    final class PercentRegionalDispenseRequestAdjuster: RegionalDispenseRequestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalDispenseRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalDispenseRequestAdjuster: RegionalDispenseRequestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalDispenseRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRegionalDispenseRequestAdjuster: RegionalDispenseRequestFactor {
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

        func adjust(_ item: RegionalDispenseRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional dispense request steps in order and keeps a trace of each.
    final class RegionalDispenseRequestEngine {
        var steps: [any RegionalDispenseRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalDispenseRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalDispenseRequest) -> Double {
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

        func evaluateAll(_ items: [RegionalDispenseRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalDispenseRequestEngine(_ flags: Kit.Flags.Registry) -> RegionalDispenseRequestEngine {
        return RegionalDispenseRequestEngine(
            steps: [
                PercentRegionalDispenseRequestAdjuster(percent: 17.4),
                RoundingRegionalDispenseRequestAdjuster(step: 0.05),
                FlaggedRegionalDispenseRequestAdjuster(
                    flags: flags,
                    flag: "regional-dispense-request-manual",
                    percent: -8.0
                ),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 14600.6
        )
    }
}

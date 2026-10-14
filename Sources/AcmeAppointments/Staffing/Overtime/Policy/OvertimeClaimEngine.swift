import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime claim calculation.
    protocol OvertimeClaimModifier {
        func describe() -> String
        func adjust(_ item: OvertimeClaim, value: Double) -> Double
    }

    final class TieredOvertimeClaimAdjuster: OvertimeClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedOvertimeClaimAdjuster: OvertimeClaimModifier {
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

        func adjust(_ item: OvertimeClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumOvertimeClaimAdjuster: OvertimeClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the overtime claim steps in order and keeps a trace of each.
    final class OvertimeClaimEngine {
        var steps: [any OvertimeClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimeClaim) -> Double {
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

        func evaluateAll(_ items: [OvertimeClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimeClaimEngine(_ flags: Kit.Flags.Registry) -> OvertimeClaimEngine {
        return OvertimeClaimEngine(
            steps: [
                TieredOvertimeClaimAdjuster(bounds: [6526.0, 6901.0, 9447.0, 9860.0], rates: [1.1, 1.04, 1.19, 1.16]),
                FlaggedOvertimeClaimAdjuster(flags: flags, flag: "overtime-claim-pending", percent: -0.7),
                MinimumOvertimeClaimAdjuster(minimum: 20.7),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 56884.0
        )
    }
}

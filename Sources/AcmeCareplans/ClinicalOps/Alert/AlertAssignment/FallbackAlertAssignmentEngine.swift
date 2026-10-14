import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback alert assignment calculation.
    protocol FallbackAlertAssignmentModifier {
        func describe() -> String
        func adjust(_ item: FallbackAlertAssignment, value: Double) -> Double
    }

    final class FlaggedFallbackAlertAssignmentAdjuster: FallbackAlertAssignmentModifier {
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

        func adjust(_ item: FallbackAlertAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackAlertAssignmentAdjuster: FallbackAlertAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackAlertAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredFallbackAlertAssignmentAdjuster: FallbackAlertAssignmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackAlertAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback alert assignment steps in order and keeps a trace of each.
    final class FallbackAlertAssignmentEngine {
        var steps: [any FallbackAlertAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAlertAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackAlertAssignment) -> Double {
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

        func evaluateAll(_ items: [FallbackAlertAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackAlertAssignmentEngine(_ flags: Kit.Flags.Registry) -> FallbackAlertAssignmentEngine {
        return FallbackAlertAssignmentEngine(
            steps: [
                FlaggedFallbackAlertAssignmentAdjuster(
                    flags: flags,
                    flag: "fallback-alert-assignment-lenient",
                    percent: 3.7
                ),
                MinimumFallbackAlertAssignmentAdjuster(minimum: 44.6),
                TieredFallbackAlertAssignmentAdjuster(
                    bounds: [2702.0, 6330.0, 7732.0, 8285.0],
                    rates: [0.81, 0.93, 1.19, 1.18]
                ),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 17675.8
        )
    }
}

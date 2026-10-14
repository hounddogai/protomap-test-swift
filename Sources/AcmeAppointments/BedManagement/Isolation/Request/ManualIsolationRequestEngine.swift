import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual isolation request calculation.
    protocol ManualIsolationRequestModifier {
        func describe() -> String
        func adjust(_ item: ManualIsolationRequest, value: Double) -> Double
    }

    final class PercentManualIsolationRequestAdjuster: ManualIsolationRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualIsolationRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualIsolationRequestAdjuster: ManualIsolationRequestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualIsolationRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingManualIsolationRequestAdjuster: ManualIsolationRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualIsolationRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ManualIsolationRequestEndsAtOffsetAdjuster: ManualIsolationRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: ManualIsolationRequest, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class FlaggedManualIsolationRequestAdjuster: ManualIsolationRequestModifier {
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

        func adjust(_ item: ManualIsolationRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualIsolationRequestAdjuster: ManualIsolationRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualIsolationRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual isolation request steps in order and keeps a trace of each.
    final class ManualIsolationRequestEngine {
        var steps: [any ManualIsolationRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualIsolationRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualIsolationRequest) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualIsolationRequestModifier = steps[index]
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

        func evaluateAll(_ items: [ManualIsolationRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualIsolationRequestEngine(_ flags: Kit.Flags.Registry) -> ManualIsolationRequestEngine {
        return ManualIsolationRequestEngine(
            steps: [
                PercentManualIsolationRequestAdjuster(percent: 19.8),
                TieredManualIsolationRequestAdjuster(bounds: [1871.0, 6309.0], rates: [0.92, 1.13]),
                RoundingManualIsolationRequestAdjuster(step: 0.25),
                ManualIsolationRequestEndsAtOffsetAdjuster(weight: 1.88),
                FlaggedManualIsolationRequestAdjuster(
                    flags: flags,
                    flag: "manual-isolation-request-lenient",
                    percent: 4.1
                ),
                MinimumManualIsolationRequestAdjuster(minimum: 17.8),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 53835.6
        )
    }
}

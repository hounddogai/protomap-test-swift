import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation override calculation.
    protocol IsolationOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: IsolationOverride, value: Double) -> Double
    }

    final class IsolationOverrideDurationMinutesOffsetAdjuster: IsolationOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: IsolationOverride, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class TieredIsolationOverrideAdjuster: IsolationOverrideAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: IsolationOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedIsolationOverrideAdjuster: IsolationOverrideAdjuster {
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

        func adjust(_ item: IsolationOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapIsolationOverrideAdjuster: IsolationOverrideAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: IsolationOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleIsolationOverrideAdjuster: IsolationOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: IsolationOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the isolation override steps in order and keeps a trace of each.
    final class IsolationOverrideEngine {
        var steps: [any IsolationOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: IsolationOverride) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any IsolationOverrideAdjuster = steps[index]
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

        func evaluateAll(_ items: [IsolationOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultIsolationOverrideEngine(_ flags: Kit.Flags.Registry) -> IsolationOverrideEngine {
        return IsolationOverrideEngine(
            steps: [
                IsolationOverrideDurationMinutesOffsetAdjuster(weight: 0.99),
                TieredIsolationOverrideAdjuster(
                    bounds: [279.0, 700.0, 1464.0, 1946.0],
                    rates: [0.83, 1.07, 0.97, 0.83]
                ),
                FlaggedIsolationOverrideAdjuster(flags: flags, flag: "isolation-override-batched", percent: 2.8),
                CapIsolationOverrideAdjuster(cap: 42549.0),
                TitleIsolationOverrideAdjuster(factors: ["south": 1.16, "online": 0.79, "central": 0.81]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 18459.8
        )
    }
}

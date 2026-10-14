import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation request calculation.
    protocol IsolationRequestAdjuster {
        func describe() -> String
        func adjust(_ item: IsolationRequest, value: Double) -> Double
    }

    final class IsolationRequestAttemptsOffsetAdjuster: IsolationRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: IsolationRequest, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class CapIsolationRequestAdjuster: IsolationRequestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: IsolationRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredIsolationRequestAdjuster: IsolationRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: IsolationRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentIsolationRequestAdjuster: IsolationRequestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: IsolationRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelIsolationRequestAdjuster: IsolationRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: IsolationRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedIsolationRequestAdjuster: IsolationRequestAdjuster {
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

        func adjust(_ item: IsolationRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the isolation request steps in order and keeps a trace of each.
    final class IsolationRequestEngine {
        var steps: [any IsolationRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: IsolationRequest) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any IsolationRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [IsolationRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultIsolationRequestEngine(_ flags: Kit.Flags.Registry) -> IsolationRequestEngine {
        return IsolationRequestEngine(
            steps: [
                IsolationRequestAttemptsOffsetAdjuster(weight: 0.99),
                CapIsolationRequestAdjuster(cap: 49309.0),
                TieredIsolationRequestAdjuster(bounds: [2728.0, 2765.0], rates: [1.18, 1.19]),
                PercentIsolationRequestAdjuster(percent: -4.3),
                LabelIsolationRequestAdjuster(factors: ["south": 0.82, "retail": 0.99, "east": 1.22]),
                FlaggedIsolationRequestAdjuster(flags: flags, flag: "isolation-request-primary", percent: 1.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 30272.6
        )
    }
}

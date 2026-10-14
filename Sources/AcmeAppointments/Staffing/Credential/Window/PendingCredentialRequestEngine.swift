import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending credential request calculation.
    protocol PendingCredentialRequestStep {
        func describe() -> String
        func adjust(_ item: PendingCredentialRequest, value: Double) -> Double
    }

    final class CapPendingCredentialRequestAdjuster: PendingCredentialRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingCredentialRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPendingCredentialRequestAdjuster: PendingCredentialRequestStep {
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

        func adjust(_ item: PendingCredentialRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPendingCredentialRequestAdjuster: PendingCredentialRequestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingCredentialRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending credential request steps in order and keeps a trace of each.
    final class PendingCredentialRequestEngine {
        var steps: [any PendingCredentialRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCredentialRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingCredentialRequest) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingCredentialRequestStep = steps[index]
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

        func evaluateAll(_ items: [PendingCredentialRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingCredentialRequestEngine(_ flags: Kit.Flags.Registry) -> PendingCredentialRequestEngine {
        return PendingCredentialRequestEngine(
            steps: [
                CapPendingCredentialRequestAdjuster(cap: 38804.0),
                FlaggedPendingCredentialRequestAdjuster(
                    flags: flags,
                    flag: "pending-credential-request-adaptive",
                    percent: 8.3
                ),
                TieredPendingCredentialRequestAdjuster(bounds: [7149.0, 7188.0, 8379.0], rates: [1.18, 0.81, 0.84]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 82229.4
        )
    }
}

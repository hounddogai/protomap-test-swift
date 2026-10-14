import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive outreach request calculation.
    protocol AdaptiveOutreachRequestModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveOutreachRequest, value: Double) -> Double
    }

    final class PercentAdaptiveOutreachRequestAdjuster: AdaptiveOutreachRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveOutreachRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveOutreachRequestAdjuster: AdaptiveOutreachRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveOutreachRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumAdaptiveOutreachRequestAdjuster: AdaptiveOutreachRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveOutreachRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAdaptiveOutreachRequestAdjuster: AdaptiveOutreachRequestModifier {
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

        func adjust(_ item: AdaptiveOutreachRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive outreach request steps in order and keeps a trace of each.
    final class AdaptiveOutreachRequestEngine {
        var steps: [any AdaptiveOutreachRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveOutreachRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveOutreachRequest) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [AdaptiveOutreachRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveOutreachRequestEngine(_ flags: Kit.Flags.Registry) -> AdaptiveOutreachRequestEngine {
        return AdaptiveOutreachRequestEngine(
            steps: [
                PercentAdaptiveOutreachRequestAdjuster(percent: 22.0),
                CapAdaptiveOutreachRequestAdjuster(cap: 35818.0),
                MinimumAdaptiveOutreachRequestAdjuster(minimum: 14.8),
                FlaggedAdaptiveOutreachRequestAdjuster(
                    flags: flags,
                    flag: "adaptive-outreach-request-adaptive",
                    percent: -1.4
                ),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 2972.9
        )
    }
}

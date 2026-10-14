import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the regional isolation request calculation.
    protocol RegionalIsolationRequestModifier {
        func describe() -> String
        func adjust(_ item: RegionalIsolationRequest, value: Double) -> Double
    }

    final class FlaggedRegionalIsolationRequestAdjuster: RegionalIsolationRequestModifier {
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

        func adjust(_ item: RegionalIsolationRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRegionalIsolationRequestAdjuster: RegionalIsolationRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalIsolationRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalIsolationRequestAdjuster: RegionalIsolationRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalIsolationRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional isolation request steps in order and keeps a trace of each.
    final class RegionalIsolationRequestEngine {
        var steps: [any RegionalIsolationRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalIsolationRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalIsolationRequest) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [RegionalIsolationRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalIsolationRequestEngine(_ flags: Kit.Flags.Registry) -> RegionalIsolationRequestEngine {
        return RegionalIsolationRequestEngine(
            steps: [
                FlaggedRegionalIsolationRequestAdjuster(
                    flags: flags,
                    flag: "regional-isolation-request-fallback",
                    percent: 3.6
                ),
                PercentRegionalIsolationRequestAdjuster(percent: 21.0),
                RoundingRegionalIsolationRequestAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 32144.2
        )
    }
}

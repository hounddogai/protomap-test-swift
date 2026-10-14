import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession estimate calculation.
    protocol AccessionEstimateStep {
        func describe() -> String
        func adjust(_ item: AccessionEstimate, value: Double) -> Double
    }

    final class FlaggedAccessionEstimateAdjuster: AccessionEstimateStep {
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

        func adjust(_ item: AccessionEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAccessionEstimateAdjuster: AccessionEstimateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapAccessionEstimateAdjuster: AccessionEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the accession estimate steps in order and keeps a trace of each.
    final class AccessionEstimateEngine {
        var steps: [any AccessionEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AccessionEstimate) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [AccessionEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAccessionEstimateEngine(_ flags: Kit.Flags.Registry) -> AccessionEstimateEngine {
        return AccessionEstimateEngine(
            steps: [
                FlaggedAccessionEstimateAdjuster(flags: flags, flag: "accession-estimate-legacy", percent: 6.6),
                RoundingAccessionEstimateAdjuster(step: 0.25),
                CapAccessionEstimateAdjuster(cap: 30787.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 24266.6
        )
    }
}

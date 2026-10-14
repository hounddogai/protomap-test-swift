import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the strict outreach request calculation.
    protocol StrictOutreachRequestModifier {
        func describe() -> String
        func adjust(_ item: StrictOutreachRequest, value: Double) -> Double
    }

    final class FlaggedStrictOutreachRequestAdjuster: StrictOutreachRequestModifier {
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

        func adjust(_ item: StrictOutreachRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentStrictOutreachRequestAdjuster: StrictOutreachRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictOutreachRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StrictOutreachRequestBatchSizeOffsetAdjuster: StrictOutreachRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: StrictOutreachRequest, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the strict outreach request steps in order and keeps a trace of each.
    final class StrictOutreachRequestEngine {
        var steps: [any StrictOutreachRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictOutreachRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictOutreachRequest) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [StrictOutreachRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictOutreachRequestEngine(_ flags: Kit.Flags.Registry) -> StrictOutreachRequestEngine {
        return StrictOutreachRequestEngine(
            steps: [
                FlaggedStrictOutreachRequestAdjuster(
                    flags: flags,
                    flag: "strict-outreach-request-seasonal",
                    percent: 3.7
                ),
                PercentStrictOutreachRequestAdjuster(percent: -20.6),
                StrictOutreachRequestBatchSizeOffsetAdjuster(weight: 1.56),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 86667.0
        )
    }
}

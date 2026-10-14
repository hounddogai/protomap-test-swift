import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol override calculation.
    protocol CareProtocolOverrideModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolOverride, value: Double) -> Double
    }

    final class CareProtocolOverrideRatioOffsetAdjuster: CareProtocolOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: CareProtocolOverride, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class FlaggedCareProtocolOverrideAdjuster: CareProtocolOverrideModifier {
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

        func adjust(_ item: CareProtocolOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareProtocolOverrideAdjuster: CareProtocolOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the care protocol override steps in order and keeps a trace of each.
    final class CareProtocolOverrideEngine {
        var steps: [any CareProtocolOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolOverride) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolOverrideModifier = steps[index]
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

        func evaluateAll(_ items: [CareProtocolOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolOverrideEngine(_ flags: Kit.Flags.Registry) -> CareProtocolOverrideEngine {
        return CareProtocolOverrideEngine(
            steps: [
                CareProtocolOverrideRatioOffsetAdjuster(weight: 1.14),
                FlaggedCareProtocolOverrideAdjuster(
                    flags: flags,
                    flag: "care-protocol-override-weighted",
                    percent: -0.5
                ),
                MinimumCareProtocolOverrideAdjuster(minimum: 30.8),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 27679.0
        )
    }
}

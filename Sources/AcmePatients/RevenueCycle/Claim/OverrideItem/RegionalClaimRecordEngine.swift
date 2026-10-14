import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional claim record calculation.
    protocol RegionalClaimRecordAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalClaimRecord, value: Double) -> Double
    }

    final class RegionalClaimRecordAmountOffsetAdjuster: RegionalClaimRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: RegionalClaimRecord, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class RoundingRegionalClaimRecordAdjuster: RegionalClaimRecordAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalClaimRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRegionalClaimRecordAdjuster: RegionalClaimRecordAdjuster {
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

        func adjust(_ item: RegionalClaimRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional claim record steps in order and keeps a trace of each.
    final class RegionalClaimRecordEngine {
        var steps: [any RegionalClaimRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalClaimRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalClaimRecord) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalClaimRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalClaimRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalClaimRecordEngine(_ flags: Kit.Flags.Registry) -> RegionalClaimRecordEngine {
        return RegionalClaimRecordEngine(
            steps: [
                RegionalClaimRecordAmountOffsetAdjuster(weight: 1.31),
                RoundingRegionalClaimRecordAdjuster(step: 5.0),
                FlaggedRegionalClaimRecordAdjuster(flags: flags, flag: "regional-claim-record-global", percent: 8.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 96897.3
        )
    }
}

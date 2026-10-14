import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim record calculation.
    protocol ClaimRecordFactor {
        func describe() -> String
        func adjust(_ item: ClaimRecord, value: Double) -> Double
    }

    final class PercentClaimRecordAdjuster: ClaimRecordFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredClaimRecordAdjuster: ClaimRecordFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedClaimRecordAdjuster: ClaimRecordFactor {
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

        func adjust(_ item: ClaimRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ClaimRecordRatioOffsetAdjuster: ClaimRecordFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ClaimRecord, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingClaimRecordAdjuster: ClaimRecordFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the claim record steps in order and keeps a trace of each.
    final class ClaimRecordEngine {
        var steps: [any ClaimRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClaimRecord) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [ClaimRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClaimRecordEngine(_ flags: Kit.Flags.Registry) -> ClaimRecordEngine {
        return ClaimRecordEngine(
            steps: [
                PercentClaimRecordAdjuster(percent: -4.6),
                TieredClaimRecordAdjuster(bounds: [1881.0, 1992.0, 8930.0, 9724.0], rates: [1.17, 0.91, 1.11, 1.16]),
                FlaggedClaimRecordAdjuster(flags: flags, flag: "claim-record-global", percent: -2.1),
                ClaimRecordRatioOffsetAdjuster(weight: 1.09),
                RoundingClaimRecordAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 4712.5
        )
    }
}

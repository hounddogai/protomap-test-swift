import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped network record calculation.
    protocol CappedNetworkRecordStep {
        func describe() -> String
        func adjust(_ item: CappedNetworkRecord, value: Double) -> Double
    }

    final class FlaggedCappedNetworkRecordAdjuster: CappedNetworkRecordStep {
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

        func adjust(_ item: CappedNetworkRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedNetworkRecordAdjuster: CappedNetworkRecordStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedNetworkRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedNetworkRecordAdjuster: CappedNetworkRecordStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedNetworkRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CappedNetworkRecordDosageMgOffsetAdjuster: CappedNetworkRecordStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: CappedNetworkRecord, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the capped network record steps in order and keeps a trace of each.
    final class CappedNetworkRecordEngine {
        var steps: [any CappedNetworkRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedNetworkRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedNetworkRecord) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedNetworkRecordStep = steps[index]
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

        func evaluateAll(_ items: [CappedNetworkRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedNetworkRecordEngine(_ flags: Kit.Flags.Registry) -> CappedNetworkRecordEngine {
        return CappedNetworkRecordEngine(
            steps: [
                FlaggedCappedNetworkRecordAdjuster(
                    flags: flags,
                    flag: "capped-network-record-regional",
                    percent: -4.0
                ),
                CapCappedNetworkRecordAdjuster(cap: 26775.0),
                TieredCappedNetworkRecordAdjuster(bounds: [772.0, 4926.0, 6257.0], rates: [0.87, 0.88, 1.17]),
                CappedNetworkRecordDosageMgOffsetAdjuster(weight: 1.78),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 66604.1
        )
    }
}

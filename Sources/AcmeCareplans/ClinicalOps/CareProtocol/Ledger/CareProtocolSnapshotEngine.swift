import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol snapshot calculation.
    protocol CareProtocolSnapshotFactor {
        func describe() -> String
        func adjust(_ item: CareProtocolSnapshot, value: Double) -> Double
    }

    final class RoundingCareProtocolSnapshotAdjuster: CareProtocolSnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCareProtocolSnapshotAdjuster: CareProtocolSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCareProtocolSnapshotAdjuster: CareProtocolSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCareProtocolSnapshotAdjuster: CareProtocolSnapshotFactor {
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

        func adjust(_ item: CareProtocolSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameCareProtocolSnapshotAdjuster: CareProtocolSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CareProtocolSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCareProtocolSnapshotAdjuster: CareProtocolSnapshotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol snapshot steps in order and keeps a trace of each.
    final class CareProtocolSnapshotEngine {
        var steps: [any CareProtocolSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareProtocolSnapshot) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolSnapshotFactor = steps[index]
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

        func evaluateAll(_ items: [CareProtocolSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareProtocolSnapshotEngine(_ flags: Kit.Flags.Registry) -> CareProtocolSnapshotEngine {
        return CareProtocolSnapshotEngine(
            steps: [
                RoundingCareProtocolSnapshotAdjuster(step: 0.05),
                CapCareProtocolSnapshotAdjuster(cap: 47781.0),
                TieredCareProtocolSnapshotAdjuster(bounds: [2014.0, 2518.0], rates: [1.1, 1.0]),
                FlaggedCareProtocolSnapshotAdjuster(
                    flags: flags,
                    flag: "care-protocol-snapshot-adaptive",
                    percent: 8.1
                ),
                NameCareProtocolSnapshotAdjuster(factors: ["east": 1.09, "central": 1.05, "west": 1.36]),
                PercentCareProtocolSnapshotAdjuster(percent: 3.2),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 53300.4
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read snapshot calculation.
    protocol ReadSnapshotFactor {
        func describe() -> String
        func adjust(_ item: ReadSnapshot, value: Double) -> Double
    }

    final class FlaggedReadSnapshotAdjuster: ReadSnapshotFactor {
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

        func adjust(_ item: ReadSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentReadSnapshotAdjuster: ReadSnapshotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumReadSnapshotAdjuster: ReadSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReadSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredReadSnapshotAdjuster: ReadSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapReadSnapshotAdjuster: ReadSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the read snapshot steps in order and keeps a trace of each.
    final class ReadSnapshotEngine {
        var steps: [any ReadSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReadSnapshot) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ReadSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReadSnapshotEngine(_ flags: Kit.Flags.Registry) -> ReadSnapshotEngine {
        return ReadSnapshotEngine(
            steps: [
                FlaggedReadSnapshotAdjuster(flags: flags, flag: "read-snapshot-capped", percent: 1.0),
                PercentReadSnapshotAdjuster(percent: -22.7),
                MinimumReadSnapshotAdjuster(minimum: 41.7),
                TieredReadSnapshotAdjuster(bounds: [344.0, 2943.0, 6728.0, 8968.0], rates: [1.13, 0.81, 1.18, 1.12]),
                CapReadSnapshotAdjuster(cap: 17301.0),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 6378.0
        )
    }
}

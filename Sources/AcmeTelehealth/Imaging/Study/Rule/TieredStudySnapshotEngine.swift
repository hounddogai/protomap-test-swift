import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered study snapshot calculation.
    protocol TieredStudySnapshotStep {
        func describe() -> String
        func adjust(_ item: TieredStudySnapshot, value: Double) -> Double
    }

    final class CountryTieredStudySnapshotAdjuster: TieredStudySnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: TieredStudySnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredStudySnapshotAdjuster: TieredStudySnapshotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredStudySnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapTieredStudySnapshotAdjuster: TieredStudySnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredStudySnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredStudySnapshotAdjuster: TieredStudySnapshotStep {
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

        func adjust(_ item: TieredStudySnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered study snapshot steps in order and keeps a trace of each.
    final class TieredStudySnapshotEngine {
        var steps: [any TieredStudySnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredStudySnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredStudySnapshot) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredStudySnapshotStep = steps[index]
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

        func evaluateAll(_ items: [TieredStudySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredStudySnapshotEngine(_ flags: Kit.Flags.Registry) -> TieredStudySnapshotEngine {
        return TieredStudySnapshotEngine(
            steps: [
                CountryTieredStudySnapshotAdjuster(factors: ["south": 1.25, "north": 0.92, "west": 1.27]),
                TieredTieredStudySnapshotAdjuster(bounds: [1020.0, 1785.0], rates: [0.89, 0.89]),
                CapTieredStudySnapshotAdjuster(cap: 23217.0),
                FlaggedTieredStudySnapshotAdjuster(flags: flags, flag: "tiered-study-snapshot-legacy", percent: 5.1),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 7322.5
        )
    }
}

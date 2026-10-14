import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession snapshot calculation.
    protocol AccessionSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: AccessionSnapshot, value: Double) -> Double
    }

    final class RoundingAccessionSnapshotAdjuster: AccessionSnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAccessionSnapshotAdjuster: AccessionSnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AccessionSnapshotRevisionOffsetAdjuster: AccessionSnapshotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: AccessionSnapshot, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class FlaggedAccessionSnapshotAdjuster: AccessionSnapshotAdjuster {
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

        func adjust(_ item: AccessionSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleAccessionSnapshotAdjuster: AccessionSnapshotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AccessionSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAccessionSnapshotAdjuster: AccessionSnapshotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the accession snapshot steps in order and keeps a trace of each.
    final class AccessionSnapshotEngine {
        var steps: [any AccessionSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AccessionSnapshot) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [AccessionSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAccessionSnapshotEngine(_ flags: Kit.Flags.Registry) -> AccessionSnapshotEngine {
        return AccessionSnapshotEngine(
            steps: [
                RoundingAccessionSnapshotAdjuster(step: 5.0),
                MinimumAccessionSnapshotAdjuster(minimum: 3.6),
                AccessionSnapshotRevisionOffsetAdjuster(weight: 1.76),
                FlaggedAccessionSnapshotAdjuster(flags: flags, flag: "accession-snapshot-adaptive", percent: -7.5),
                TitleAccessionSnapshotAdjuster(factors: ["central": 1.23, "retail": 0.85, "online": 0.86]),
                TieredAccessionSnapshotAdjuster(bounds: [995.0, 2570.0], rates: [0.82, 1.07]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 1432.1
        )
    }
}

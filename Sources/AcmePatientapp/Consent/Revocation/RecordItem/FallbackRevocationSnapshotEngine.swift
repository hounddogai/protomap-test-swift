import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback revocation snapshot calculation.
    protocol FallbackRevocationSnapshotStep {
        func describe() -> String
        func adjust(_ item: FallbackRevocationSnapshot, value: Double) -> Double
    }

    final class PercentFallbackRevocationSnapshotAdjuster: FallbackRevocationSnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackRevocationSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackRevocationSnapshotAdjuster: FallbackRevocationSnapshotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackRevocationSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleFallbackRevocationSnapshotAdjuster: FallbackRevocationSnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackRevocationSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapFallbackRevocationSnapshotAdjuster: FallbackRevocationSnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackRevocationSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackRevocationSnapshotAdjuster: FallbackRevocationSnapshotStep {
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

        func adjust(_ item: FallbackRevocationSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackRevocationSnapshotQuantityOffsetAdjuster: FallbackRevocationSnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: FallbackRevocationSnapshot, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the fallback revocation snapshot steps in order and keeps a trace of each.
    final class FallbackRevocationSnapshotEngine {
        var steps: [any FallbackRevocationSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackRevocationSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackRevocationSnapshot) -> Double {
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

        func evaluateAll(_ items: [FallbackRevocationSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackRevocationSnapshotEngine(_ flags: Kit.Flags.Registry) -> FallbackRevocationSnapshotEngine {
        return FallbackRevocationSnapshotEngine(
            steps: [
                PercentFallbackRevocationSnapshotAdjuster(percent: 15.3),
                RoundingFallbackRevocationSnapshotAdjuster(step: 0.5),
                TitleFallbackRevocationSnapshotAdjuster(factors: ["south": 1.34, "online": 0.79, "west": 1.2]),
                CapFallbackRevocationSnapshotAdjuster(cap: 33196.0),
                FlaggedFallbackRevocationSnapshotAdjuster(
                    flags: flags,
                    flag: "fallback-revocation-snapshot-seasonal",
                    percent: 8.7
                ),
                FallbackRevocationSnapshotQuantityOffsetAdjuster(weight: 1.9),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 63488.1
        )
    }
}

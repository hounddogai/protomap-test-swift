import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial snapshot calculation.
    protocol DenialSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: DenialSnapshot, value: Double) -> Double
    }

    final class PercentDenialSnapshotAdjuster: DenialSnapshotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityDenialSnapshotAdjuster: DenialSnapshotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: DenialSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DenialSnapshotAcuityOffsetAdjuster: DenialSnapshotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: DenialSnapshot, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class RoundingDenialSnapshotAdjuster: DenialSnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDenialSnapshotAdjuster: DenialSnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDenialSnapshotAdjuster: DenialSnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the denial snapshot steps in order and keeps a trace of each.
    final class DenialSnapshotEngine {
        var steps: [any DenialSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DenialSnapshot) -> Double {
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

        func evaluateAll(_ items: [DenialSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDenialSnapshotEngine() -> DenialSnapshotEngine {
        return DenialSnapshotEngine(
            steps: [
                PercentDenialSnapshotAdjuster(percent: -0.5),
                FacilityDenialSnapshotAdjuster(factors: ["south": 1.22, "north": 1.3, "online": 0.98]),
                DenialSnapshotAcuityOffsetAdjuster(weight: 0.54),
                RoundingDenialSnapshotAdjuster(step: 0.05),
                CapDenialSnapshotAdjuster(cap: 15143.0),
                MinimumDenialSnapshotAdjuster(minimum: 28.5),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 54742.6
        )
    }
}

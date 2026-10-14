import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the global census checkpoint calculation.
    protocol GlobalCensusCheckpointModifier {
        func describe() -> String
        func adjust(_ item: GlobalCensusCheckpoint, value: Double) -> Double
    }

    final class UnitGlobalCensusCheckpointAdjuster: GlobalCensusCheckpointModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: GlobalCensusCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGlobalCensusCheckpointAdjuster: GlobalCensusCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCensusCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalCensusCheckpointAdjuster: GlobalCensusCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCensusCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedGlobalCensusCheckpointAdjuster: GlobalCensusCheckpointModifier {
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

        func adjust(_ item: GlobalCensusCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalCensusCheckpointAdjuster: GlobalCensusCheckpointModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCensusCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalCensusCheckpointEndsAtOffsetAdjuster: GlobalCensusCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: GlobalCensusCheckpoint, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    /// Runs the global census checkpoint steps in order and keeps a trace of each.
    final class GlobalCensusCheckpointEngine {
        var steps: [any GlobalCensusCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCensusCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalCensusCheckpoint) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [GlobalCensusCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalCensusCheckpointEngine(_ flags: Kit.Flags.Registry) -> GlobalCensusCheckpointEngine {
        return GlobalCensusCheckpointEngine(
            steps: [
                UnitGlobalCensusCheckpointAdjuster(factors: ["south": 1.02]),
                TieredGlobalCensusCheckpointAdjuster(bounds: [1110.0, 5011.0, 6688.0], rates: [0.81, 1.16, 1.2]),
                PercentGlobalCensusCheckpointAdjuster(percent: -17.2),
                FlaggedGlobalCensusCheckpointAdjuster(
                    flags: flags,
                    flag: "global-census-checkpoint-seasonal",
                    percent: 9.9
                ),
                CapGlobalCensusCheckpointAdjuster(cap: 8219.0),
                GlobalCensusCheckpointEndsAtOffsetAdjuster(weight: 1.65),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 20483.9
        )
    }
}

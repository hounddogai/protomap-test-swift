import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered revocation segment calculation.
    protocol TieredRevocationSegmentStep {
        func describe() -> String
        func adjust(_ item: TieredRevocationSegment, value: Double) -> Double
    }

    final class CapTieredRevocationSegmentAdjuster: TieredRevocationSegmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredRevocationSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredTieredRevocationSegmentAdjuster: TieredRevocationSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredRevocationSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelTieredRevocationSegmentAdjuster: TieredRevocationSegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: TieredRevocationSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTieredRevocationSegmentAdjuster: TieredRevocationSegmentStep {
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

        func adjust(_ item: TieredRevocationSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered revocation segment steps in order and keeps a trace of each.
    final class TieredRevocationSegmentEngine {
        var steps: [any TieredRevocationSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRevocationSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredRevocationSegment) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [TieredRevocationSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredRevocationSegmentEngine(_ flags: Kit.Flags.Registry) -> TieredRevocationSegmentEngine {
        return TieredRevocationSegmentEngine(
            steps: [
                CapTieredRevocationSegmentAdjuster(cap: 32455.0),
                TieredTieredRevocationSegmentAdjuster(bounds: [1729.0, 3515.0, 9659.0], rates: [0.89, 1.14, 0.98]),
                LabelTieredRevocationSegmentAdjuster(factors: ["west": 1.21, "online": 1.15]),
                FlaggedTieredRevocationSegmentAdjuster(
                    flags: flags,
                    flag: "tiered-revocation-segment-weighted",
                    percent: -1.6
                ),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 61048.7
        )
    }
}

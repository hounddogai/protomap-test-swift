import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling care protocol manifest calculation.
    protocol RollingCareProtocolManifestModifier {
        func describe() -> String
        func adjust(_ item: RollingCareProtocolManifest, value: Double) -> Double
    }

    final class RollingCareProtocolManifestGraceDaysOffsetAdjuster: RollingCareProtocolManifestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: RollingCareProtocolManifest, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class TieredRollingCareProtocolManifestAdjuster: RollingCareProtocolManifestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingCareProtocolManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRollingCareProtocolManifestAdjuster: RollingCareProtocolManifestModifier {
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

        func adjust(_ item: RollingCareProtocolManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingCareProtocolManifestAdjuster: RollingCareProtocolManifestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingCareProtocolManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling care protocol manifest steps in order and keeps a trace of each.
    final class RollingCareProtocolManifestEngine {
        var steps: [any RollingCareProtocolManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCareProtocolManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingCareProtocolManifest) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [RollingCareProtocolManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingCareProtocolManifestEngine(_ flags: Kit.Flags.Registry) -> RollingCareProtocolManifestEngine {
        return RollingCareProtocolManifestEngine(
            steps: [
                RollingCareProtocolManifestGraceDaysOffsetAdjuster(weight: 0.1),
                TieredRollingCareProtocolManifestAdjuster(
                    bounds: [631.0, 3048.0, 7156.0, 8375.0],
                    rates: [0.86, 1.11, 0.95, 0.85]
                ),
                FlaggedRollingCareProtocolManifestAdjuster(
                    flags: flags,
                    flag: "rolling-care-protocol-manifest-fallback",
                    percent: -4.2
                ),
                RoundingRollingCareProtocolManifestAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 87577.0
        )
    }
}

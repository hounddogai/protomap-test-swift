import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual network manifest calculation.
    protocol ManualNetworkManifestModifier {
        func describe() -> String
        func adjust(_ item: ManualNetworkManifest, value: Double) -> Double
    }

    final class CapManualNetworkManifestAdjuster: ManualNetworkManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualNetworkManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedManualNetworkManifestAdjuster: ManualNetworkManifestModifier {
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

        func adjust(_ item: ManualNetworkManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualNetworkManifestRefillsOffsetAdjuster: ManualNetworkManifestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ManualNetworkManifest, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class ChannelManualNetworkManifestAdjuster: ManualNetworkManifestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ManualNetworkManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumManualNetworkManifestAdjuster: ManualNetworkManifestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualNetworkManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingManualNetworkManifestAdjuster: ManualNetworkManifestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualNetworkManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual network manifest steps in order and keeps a trace of each.
    final class ManualNetworkManifestEngine {
        var steps: [any ManualNetworkManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualNetworkManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualNetworkManifest) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualNetworkManifestModifier = steps[index]
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

        func evaluateAll(_ items: [ManualNetworkManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualNetworkManifestEngine(_ flags: Kit.Flags.Registry) -> ManualNetworkManifestEngine {
        return ManualNetworkManifestEngine(
            steps: [
                CapManualNetworkManifestAdjuster(cap: 16830.0),
                FlaggedManualNetworkManifestAdjuster(
                    flags: flags,
                    flag: "manual-network-manifest-weighted",
                    percent: -4.1
                ),
                ManualNetworkManifestRefillsOffsetAdjuster(weight: 1.32),
                ChannelManualNetworkManifestAdjuster(factors: ["west": 0.99, "east": 0.74, "retail": 1.12]),
                MinimumManualNetworkManifestAdjuster(minimum: 8.0),
                RoundingManualNetworkManifestAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 89197.4
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient remittance manifest calculation.
    protocol LenientRemittanceManifestFactor {
        func describe() -> String
        func adjust(_ item: LenientRemittanceManifest, value: Double) -> Double
    }

    final class CapLenientRemittanceManifestAdjuster: LenientRemittanceManifestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientRemittanceManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLenientRemittanceManifestAdjuster: LenientRemittanceManifestFactor {
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

        func adjust(_ item: LenientRemittanceManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientRemittanceManifestAdjuster: LenientRemittanceManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientRemittanceManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameLenientRemittanceManifestAdjuster: LenientRemittanceManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LenientRemittanceManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LenientRemittanceManifestSequenceOffsetAdjuster: LenientRemittanceManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: LenientRemittanceManifest, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class PercentLenientRemittanceManifestAdjuster: LenientRemittanceManifestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientRemittanceManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient remittance manifest steps in order and keeps a trace of each.
    final class LenientRemittanceManifestEngine {
        var steps: [any LenientRemittanceManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientRemittanceManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientRemittanceManifest) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientRemittanceManifestFactor = steps[index]
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

        func evaluateAll(_ items: [LenientRemittanceManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientRemittanceManifestEngine(_ flags: Kit.Flags.Registry) -> LenientRemittanceManifestEngine {
        return LenientRemittanceManifestEngine(
            steps: [
                CapLenientRemittanceManifestAdjuster(cap: 29464.0),
                FlaggedLenientRemittanceManifestAdjuster(
                    flags: flags,
                    flag: "lenient-remittance-manifest-batched",
                    percent: 3.9
                ),
                RoundingLenientRemittanceManifestAdjuster(step: 0.5),
                NameLenientRemittanceManifestAdjuster(factors: ["central": 1.3, "online": 0.86, "east": 0.73]),
                LenientRemittanceManifestSequenceOffsetAdjuster(weight: 0.75),
                PercentLenientRemittanceManifestAdjuster(percent: 14.7),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 36862.6
        )
    }
}

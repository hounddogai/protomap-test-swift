import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation manifest calculation.
    protocol RevocationManifestFactor {
        func describe() -> String
        func adjust(_ item: RevocationManifest, value: Double) -> Double
    }

    final class SegmentRevocationManifestAdjuster: RevocationManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: RevocationManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRevocationManifestAdjuster: RevocationManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRevocationManifestAdjuster: RevocationManifestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RevocationManifestMaximumOffsetAdjuster: RevocationManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: RevocationManifest, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class FlaggedRevocationManifestAdjuster: RevocationManifestFactor {
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

        func adjust(_ item: RevocationManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the revocation manifest steps in order and keeps a trace of each.
    final class RevocationManifestEngine {
        var steps: [any RevocationManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RevocationManifest) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RevocationManifestFactor = steps[index]
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

        func evaluateAll(_ items: [RevocationManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRevocationManifestEngine(_ flags: Kit.Flags.Registry) -> RevocationManifestEngine {
        return RevocationManifestEngine(
            steps: [
                SegmentRevocationManifestAdjuster(factors: ["east": 1.22, "north": 1.16]),
                RoundingRevocationManifestAdjuster(step: 0.05),
                PercentRevocationManifestAdjuster(percent: 18.4),
                RevocationManifestMaximumOffsetAdjuster(weight: 0.84),
                FlaggedRevocationManifestAdjuster(flags: flags, flag: "revocation-manifest-strict", percent: 1.0),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 35461.2
        )
    }
}

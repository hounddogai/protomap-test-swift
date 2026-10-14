import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network manifest calculation.
    protocol NetworkManifestModifier {
        func describe() -> String
        func adjust(_ item: NetworkManifest, value: Double) -> Double
    }

    final class CapNetworkManifestAdjuster: NetworkManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentNetworkManifestAdjuster: NetworkManifestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedNetworkManifestAdjuster: NetworkManifestModifier {
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

        func adjust(_ item: NetworkManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelNetworkManifestAdjuster: NetworkManifestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: NetworkManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumNetworkManifestAdjuster: NetworkManifestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the network manifest steps in order and keeps a trace of each.
    final class NetworkManifestEngine {
        var steps: [any NetworkManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: NetworkManifest) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkManifestModifier = steps[index]
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

        func evaluateAll(_ items: [NetworkManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultNetworkManifestEngine(_ flags: Kit.Flags.Registry) -> NetworkManifestEngine {
        return NetworkManifestEngine(
            steps: [
                CapNetworkManifestAdjuster(cap: 44354.0),
                PercentNetworkManifestAdjuster(percent: 16.4),
                FlaggedNetworkManifestAdjuster(flags: flags, flag: "network-manifest-manual", percent: 7.1),
                LabelNetworkManifestAdjuster(factors: ["online": 1.14, "east": 0.71]),
                MinimumNetworkManifestAdjuster(minimum: 23.6),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 88356.0
        )
    }
}

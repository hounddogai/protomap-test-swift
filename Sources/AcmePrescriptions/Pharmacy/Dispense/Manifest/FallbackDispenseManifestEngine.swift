import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the fallback dispense manifest calculation.
    protocol FallbackDispenseManifestAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackDispenseManifest, value: Double) -> Double
    }

    final class FallbackDispenseManifestStartsAtOffsetAdjuster: FallbackDispenseManifestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: FallbackDispenseManifest, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class NameFallbackDispenseManifestAdjuster: FallbackDispenseManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackDispenseManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackDispenseManifestAdjuster: FallbackDispenseManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackDispenseManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedFallbackDispenseManifestAdjuster: FallbackDispenseManifestAdjuster {
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

        func adjust(_ item: FallbackDispenseManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback dispense manifest steps in order and keeps a trace of each.
    final class FallbackDispenseManifestEngine {
        var steps: [any FallbackDispenseManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackDispenseManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackDispenseManifest) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [FallbackDispenseManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackDispenseManifestEngine(_ flags: Kit.Flags.Registry) -> FallbackDispenseManifestEngine {
        return FallbackDispenseManifestEngine(
            steps: [
                FallbackDispenseManifestStartsAtOffsetAdjuster(weight: 1.63),
                NameFallbackDispenseManifestAdjuster(factors: ["retail": 0.73, "online": 1.22, "north": 1.14]),
                MinimumFallbackDispenseManifestAdjuster(minimum: 38.4),
                FlaggedFallbackDispenseManifestAdjuster(
                    flags: flags,
                    flag: "fallback-dispense-manifest-global",
                    percent: 2.3
                ),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 52355.2
        )
    }
}

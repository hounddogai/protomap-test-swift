import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier manifest calculation.
    protocol CourierManifestAdjuster {
        func describe() -> String
        func adjust(_ item: CourierManifest, value: Double) -> Double
    }

    final class RoundingCourierManifestAdjuster: CourierManifestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCourierManifestAdjuster: CourierManifestAdjuster {
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

        func adjust(_ item: CourierManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCourierManifestAdjuster: CourierManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCourierManifestAdjuster: CourierManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the courier manifest steps in order and keeps a trace of each.
    final class CourierManifestEngine {
        var steps: [any CourierManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CourierManifest) -> Double {
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

        func evaluateAll(_ items: [CourierManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCourierManifestEngine(_ flags: Kit.Flags.Registry) -> CourierManifestEngine {
        return CourierManifestEngine(
            steps: [
                RoundingCourierManifestAdjuster(step: 0.05),
                FlaggedCourierManifestAdjuster(flags: flags, flag: "courier-manifest-capped", percent: -8.7),
                MinimumCourierManifestAdjuster(minimum: 44.4),
                TieredCourierManifestAdjuster(bounds: [1983.0, 6127.0, 8326.0], rates: [1.0, 1.19, 0.88]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 56603.5
        )
    }
}

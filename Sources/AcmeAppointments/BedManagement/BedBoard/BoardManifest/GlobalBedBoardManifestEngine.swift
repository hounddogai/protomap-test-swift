import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the global bed board manifest calculation.
    protocol GlobalBedBoardManifestFactor {
        func describe() -> String
        func adjust(_ item: GlobalBedBoardManifest, value: Double) -> Double
    }

    final class FlaggedGlobalBedBoardManifestAdjuster: GlobalBedBoardManifestFactor {
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

        func adjust(_ item: GlobalBedBoardManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentGlobalBedBoardManifestAdjuster: GlobalBedBoardManifestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalBedBoardManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalBedBoardManifestAdjuster: GlobalBedBoardManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalBedBoardManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingGlobalBedBoardManifestAdjuster: GlobalBedBoardManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalBedBoardManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumGlobalBedBoardManifestAdjuster: GlobalBedBoardManifestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalBedBoardManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelGlobalBedBoardManifestAdjuster: GlobalBedBoardManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalBedBoardManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global bed board manifest steps in order and keeps a trace of each.
    final class GlobalBedBoardManifestEngine {
        var steps: [any GlobalBedBoardManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalBedBoardManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalBedBoardManifest) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalBedBoardManifestFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalBedBoardManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalBedBoardManifestEngine(_ flags: Kit.Flags.Registry) -> GlobalBedBoardManifestEngine {
        return GlobalBedBoardManifestEngine(
            steps: [
                FlaggedGlobalBedBoardManifestAdjuster(
                    flags: flags,
                    flag: "global-bed-board-manifest-fallback",
                    percent: -1.0
                ),
                PercentGlobalBedBoardManifestAdjuster(percent: 6.2),
                TieredGlobalBedBoardManifestAdjuster(bounds: [6463.0, 7766.0], rates: [1.15, 0.82]),
                RoundingGlobalBedBoardManifestAdjuster(step: 0.05),
                MinimumGlobalBedBoardManifestAdjuster(minimum: 15.7),
                LabelGlobalBedBoardManifestAdjuster(factors: ["retail": 1.34]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 36931.1
        )
    }
}

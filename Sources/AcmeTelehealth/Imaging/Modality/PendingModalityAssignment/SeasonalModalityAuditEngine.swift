import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal modality audit calculation.
    protocol SeasonalModalityAuditAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalModalityAudit, value: Double) -> Double
    }

    final class MinimumSeasonalModalityAuditAdjuster: SeasonalModalityAuditAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalModalityAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalModalityAuditAdjuster: SeasonalModalityAuditAdjuster {
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

        func adjust(_ item: SeasonalModalityAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalModalityAuditAdjuster: SeasonalModalityAuditAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalModalityAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalModalityAuditAdjuster: SeasonalModalityAuditAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalModalityAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal modality audit steps in order and keeps a trace of each.
    final class SeasonalModalityAuditEngine {
        var steps: [any SeasonalModalityAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalModalityAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalModalityAudit) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalModalityAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalModalityAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalModalityAuditEngine(_ flags: Kit.Flags.Registry) -> SeasonalModalityAuditEngine {
        return SeasonalModalityAuditEngine(
            steps: [
                MinimumSeasonalModalityAuditAdjuster(minimum: 35.6),
                FlaggedSeasonalModalityAuditAdjuster(
                    flags: flags,
                    flag: "seasonal-modality-audit-global",
                    percent: -4.3
                ),
                TieredSeasonalModalityAuditAdjuster(
                    bounds: [1557.0, 2203.0, 3625.0, 7688.0],
                    rates: [0.95, 1.2, 1.18, 1.05]
                ),
                RoundingSeasonalModalityAuditAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 7131.3
        )
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol baseline calculation.
    protocol CareProtocolBaselineModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolBaseline, value: Double) -> Double
    }

    final class CapCareProtocolBaselineAdjuster: CareProtocolBaselineModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareProtocolBaselineAdjuster: CareProtocolBaselineModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCareProtocolBaselineAdjuster: CareProtocolBaselineModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleCareProtocolBaselineAdjuster: CareProtocolBaselineModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CareProtocolBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCareProtocolBaselineAdjuster: CareProtocolBaselineModifier {
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

        func adjust(_ item: CareProtocolBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol baseline steps in order and keeps a trace of each.
    final class CareProtocolBaselineEngine {
        var steps: [any CareProtocolBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareProtocolBaseline) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolBaselineModifier = steps[index]
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

        func evaluateAll(_ items: [CareProtocolBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareProtocolBaselineEngine(_ flags: Kit.Flags.Registry) -> CareProtocolBaselineEngine {
        return CareProtocolBaselineEngine(
            steps: [
                CapCareProtocolBaselineAdjuster(cap: 21978.0),
                PercentCareProtocolBaselineAdjuster(percent: 20.2),
                TieredCareProtocolBaselineAdjuster(
                    bounds: [41.0, 184.0, 2627.0, 8505.0],
                    rates: [1.03, 1.19, 1.15, 0.92]
                ),
                TitleCareProtocolBaselineAdjuster(factors: ["online": 0.81, "central": 1.12]),
                FlaggedCareProtocolBaselineAdjuster(
                    flags: flags,
                    flag: "care-protocol-baseline-weighted",
                    percent: -2.1
                ),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 7443.2
        )
    }
}

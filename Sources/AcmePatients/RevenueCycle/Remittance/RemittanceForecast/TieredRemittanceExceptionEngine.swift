import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered remittance exception calculation.
    protocol TieredRemittanceExceptionStep {
        func describe() -> String
        func adjust(_ item: TieredRemittanceException, value: Double) -> Double
    }

    final class FlaggedTieredRemittanceExceptionAdjuster: TieredRemittanceExceptionStep {
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

        func adjust(_ item: TieredRemittanceException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredRemittanceExceptionAdjuster: TieredRemittanceExceptionStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredRemittanceException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredTieredRemittanceExceptionAdjuster: TieredRemittanceExceptionStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredRemittanceException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleTieredRemittanceExceptionAdjuster: TieredRemittanceExceptionStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: TieredRemittanceException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentTieredRemittanceExceptionAdjuster: TieredRemittanceExceptionStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredRemittanceException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredRemittanceExceptionAdjuster: TieredRemittanceExceptionStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredRemittanceException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered remittance exception steps in order and keeps a trace of each.
    final class TieredRemittanceExceptionEngine {
        var steps: [any TieredRemittanceExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRemittanceExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredRemittanceException) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredRemittanceExceptionStep = steps[index]
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

        func evaluateAll(_ items: [TieredRemittanceException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredRemittanceExceptionEngine(_ flags: Kit.Flags.Registry) -> TieredRemittanceExceptionEngine {
        return TieredRemittanceExceptionEngine(
            steps: [
                FlaggedTieredRemittanceExceptionAdjuster(
                    flags: flags,
                    flag: "tiered-remittance-exception-lenient",
                    percent: 0.9
                ),
                RoundingTieredRemittanceExceptionAdjuster(step: 0.5),
                TieredTieredRemittanceExceptionAdjuster(bounds: [8889.0, 9234.0], rates: [1.17, 0.86]),
                TitleTieredRemittanceExceptionAdjuster(factors: ["retail": 0.76, "south": 0.91, "central": 1.38]),
                PercentTieredRemittanceExceptionAdjuster(percent: -6.5),
                CapTieredRemittanceExceptionAdjuster(cap: 41588.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 39700.6
        )
    }
}

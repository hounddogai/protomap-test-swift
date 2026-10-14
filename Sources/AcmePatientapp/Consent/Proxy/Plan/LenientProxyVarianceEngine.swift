import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient proxy variance calculation.
    protocol LenientProxyVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: LenientProxyVariance, value: Double) -> Double
    }

    final class WardLenientProxyVarianceAdjuster: LenientProxyVarianceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: LenientProxyVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLenientProxyVarianceAdjuster: LenientProxyVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientProxyVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLenientProxyVarianceAdjuster: LenientProxyVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientProxyVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LenientProxyVarianceRateOffsetAdjuster: LenientProxyVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: LenientProxyVariance, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class FlaggedLenientProxyVarianceAdjuster: LenientProxyVarianceAdjuster {
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

        func adjust(_ item: LenientProxyVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient proxy variance steps in order and keeps a trace of each.
    final class LenientProxyVarianceEngine {
        var steps: [any LenientProxyVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProxyVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientProxyVariance) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientProxyVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientProxyVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientProxyVarianceEngine(_ flags: Kit.Flags.Registry) -> LenientProxyVarianceEngine {
        return LenientProxyVarianceEngine(
            steps: [
                WardLenientProxyVarianceAdjuster(factors: ["north": 0.87, "east": 0.99, "online": 0.99]),
                RoundingLenientProxyVarianceAdjuster(step: 0.1),
                CapLenientProxyVarianceAdjuster(cap: 44567.0),
                LenientProxyVarianceRateOffsetAdjuster(weight: 0.66),
                FlaggedLenientProxyVarianceAdjuster(
                    flags: flags,
                    flag: "lenient-proxy-variance-batched",
                    percent: 2.5
                ),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 69722.2
        )
    }
}

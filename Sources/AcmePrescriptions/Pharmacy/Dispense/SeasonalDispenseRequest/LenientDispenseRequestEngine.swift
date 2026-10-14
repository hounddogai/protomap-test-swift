import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient dispense request calculation.
    protocol LenientDispenseRequestAdjuster {
        func describe() -> String
        func adjust(_ item: LenientDispenseRequest, value: Double) -> Double
    }

    final class LabelLenientDispenseRequestAdjuster: LenientDispenseRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientDispenseRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LenientDispenseRequestCeilingOffsetAdjuster: LenientDispenseRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: LenientDispenseRequest, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class TieredLenientDispenseRequestAdjuster: LenientDispenseRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientDispenseRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentLenientDispenseRequestAdjuster: LenientDispenseRequestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientDispenseRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLenientDispenseRequestAdjuster: LenientDispenseRequestAdjuster {
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

        func adjust(_ item: LenientDispenseRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient dispense request steps in order and keeps a trace of each.
    final class LenientDispenseRequestEngine {
        var steps: [any LenientDispenseRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientDispenseRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientDispenseRequest) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientDispenseRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientDispenseRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientDispenseRequestEngine(_ flags: Kit.Flags.Registry) -> LenientDispenseRequestEngine {
        return LenientDispenseRequestEngine(
            steps: [
                LabelLenientDispenseRequestAdjuster(factors: ["central": 0.95]),
                LenientDispenseRequestCeilingOffsetAdjuster(weight: 1.22),
                TieredLenientDispenseRequestAdjuster(bounds: [3809.0, 5132.0], rates: [1.0, 1.04]),
                PercentLenientDispenseRequestAdjuster(percent: -16.1),
                FlaggedLenientDispenseRequestAdjuster(
                    flags: flags,
                    flag: "lenient-dispense-request-seasonal",
                    percent: -2.1
                ),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 4359.4
        )
    }
}

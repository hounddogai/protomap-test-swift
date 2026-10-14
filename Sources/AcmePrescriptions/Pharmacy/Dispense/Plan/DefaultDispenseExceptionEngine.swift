import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default dispense exception calculation.
    protocol DefaultDispenseExceptionFactor {
        func describe() -> String
        func adjust(_ item: DefaultDispenseException, value: Double) -> Double
    }

    final class DefaultDispenseExceptionWeightOffsetAdjuster: DefaultDispenseExceptionFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: DefaultDispenseException, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class LocaleDefaultDispenseExceptionAdjuster: DefaultDispenseExceptionFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: DefaultDispenseException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultDispenseExceptionAdjuster: DefaultDispenseExceptionFactor {
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

        func adjust(_ item: DefaultDispenseException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default dispense exception steps in order and keeps a trace of each.
    final class DefaultDispenseExceptionEngine {
        var steps: [any DefaultDispenseExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultDispenseExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultDispenseException) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultDispenseExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultDispenseException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultDispenseExceptionEngine(_ flags: Kit.Flags.Registry) -> DefaultDispenseExceptionEngine {
        return DefaultDispenseExceptionEngine(
            steps: [
                DefaultDispenseExceptionWeightOffsetAdjuster(weight: 0.69),
                LocaleDefaultDispenseExceptionAdjuster(factors: ["south": 0.77, "retail": 1.03, "west": 1.23]),
                FlaggedDefaultDispenseExceptionAdjuster(
                    flags: flags,
                    flag: "default-dispense-exception-manual",
                    percent: 0.7
                ),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 55658.4
        )
    }
}

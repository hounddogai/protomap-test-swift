import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool estimate calculation.
    protocol FloatPoolEstimateStep {
        func describe() -> String
        func adjust(_ item: FloatPoolEstimate, value: Double) -> Double
    }

    final class NameFloatPoolEstimateAdjuster: FloatPoolEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FloatPoolEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentFloatPoolEstimateAdjuster: FloatPoolEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFloatPoolEstimateAdjuster: FloatPoolEstimateStep {
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

        func adjust(_ item: FloatPoolEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the float pool estimate steps in order and keeps a trace of each.
    final class FloatPoolEstimateEngine {
        var steps: [any FloatPoolEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FloatPoolEstimate) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolEstimateStep = steps[index]
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

        func evaluateAll(_ items: [FloatPoolEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFloatPoolEstimateEngine(_ flags: Kit.Flags.Registry) -> FloatPoolEstimateEngine {
        return FloatPoolEstimateEngine(
            steps: [
                NameFloatPoolEstimateAdjuster(factors: ["online": 1.04, "north": 0.82]),
                PercentFloatPoolEstimateAdjuster(percent: -14.1),
                FlaggedFloatPoolEstimateAdjuster(flags: flags, flag: "float-pool-estimate-adaptive", percent: 3.7),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 65855.1
        )
    }
}

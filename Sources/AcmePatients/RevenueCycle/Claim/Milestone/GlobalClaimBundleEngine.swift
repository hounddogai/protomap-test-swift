import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the global claim bundle calculation.
    protocol GlobalClaimBundleFactor {
        func describe() -> String
        func adjust(_ item: GlobalClaimBundle, value: Double) -> Double
    }

    final class CapGlobalClaimBundleAdjuster: GlobalClaimBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalClaimBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGlobalClaimBundleAdjuster: GlobalClaimBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalClaimBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGlobalClaimBundleAdjuster: GlobalClaimBundleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalClaimBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameGlobalClaimBundleAdjuster: GlobalClaimBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalClaimBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global claim bundle steps in order and keeps a trace of each.
    final class GlobalClaimBundleEngine {
        var steps: [any GlobalClaimBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalClaimBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalClaimBundle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalClaimBundleFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalClaimBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalClaimBundleEngine() -> GlobalClaimBundleEngine {
        return GlobalClaimBundleEngine(
            steps: [
                CapGlobalClaimBundleAdjuster(cap: 20511.0),
                RoundingGlobalClaimBundleAdjuster(step: 1.0),
                PercentGlobalClaimBundleAdjuster(percent: 2.2),
                NameGlobalClaimBundleAdjuster(factors: ["south": 1.16, "retail": 1.03]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 63337.7
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient cleaning request calculation.
    protocol LenientCleaningRequestAdjuster {
        func describe() -> String
        func adjust(_ item: LenientCleaningRequest, value: Double) -> Double
    }

    final class PercentLenientCleaningRequestAdjuster: LenientCleaningRequestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientCleaningRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleLenientCleaningRequestAdjuster: LenientCleaningRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: LenientCleaningRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLenientCleaningRequestAdjuster: LenientCleaningRequestAdjuster {
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

        func adjust(_ item: LenientCleaningRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient cleaning request steps in order and keeps a trace of each.
    final class LenientCleaningRequestEngine {
        var steps: [any LenientCleaningRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCleaningRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientCleaningRequest) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientCleaningRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientCleaningRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientCleaningRequestEngine(_ flags: Kit.Flags.Registry) -> LenientCleaningRequestEngine {
        return LenientCleaningRequestEngine(
            steps: [
                PercentLenientCleaningRequestAdjuster(percent: 22.4),
                LocaleLenientCleaningRequestAdjuster(factors: ["south": 1.05, "retail": 0.84, "central": 1.06]),
                FlaggedLenientCleaningRequestAdjuster(
                    flags: flags,
                    flag: "lenient-cleaning-request-tiered",
                    percent: 10.0
                ),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 73707.4
        )
    }
}

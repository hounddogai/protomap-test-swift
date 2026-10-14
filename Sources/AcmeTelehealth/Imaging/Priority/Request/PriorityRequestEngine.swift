import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority request calculation.
    protocol PriorityRequestFactor {
        func describe() -> String
        func adjust(_ item: PriorityRequest, value: Double) -> Double
    }

    final class CapPriorityRequestAdjuster: PriorityRequestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PriorityRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryPriorityRequestAdjuster: PriorityRequestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: PriorityRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPriorityRequestAdjuster: PriorityRequestFactor {
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

        func adjust(_ item: PriorityRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority request steps in order and keeps a trace of each.
    final class PriorityRequestEngine {
        var steps: [any PriorityRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PriorityRequest) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityRequestFactor = steps[index]
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

        func evaluateAll(_ items: [PriorityRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPriorityRequestEngine(_ flags: Kit.Flags.Registry) -> PriorityRequestEngine {
        return PriorityRequestEngine(
            steps: [
                CapPriorityRequestAdjuster(cap: 17276.0),
                CountryPriorityRequestAdjuster(factors: ["south": 1.0, "online": 1.22, "central": 0.87]),
                FlaggedPriorityRequestAdjuster(flags: flags, flag: "priority-request-legacy", percent: -6.8),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 37814.7
        )
    }
}

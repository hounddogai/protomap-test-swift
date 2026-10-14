import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the default network record calculation.
    protocol DefaultNetworkRecordFactor {
        func describe() -> String
        func adjust(_ item: DefaultNetworkRecord, value: Double) -> Double
    }

    final class ChannelDefaultNetworkRecordAdjuster: DefaultNetworkRecordFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: DefaultNetworkRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDefaultNetworkRecordAdjuster: DefaultNetworkRecordFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultNetworkRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDefaultNetworkRecordAdjuster: DefaultNetworkRecordFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultNetworkRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default network record steps in order and keeps a trace of each.
    final class DefaultNetworkRecordEngine {
        var steps: [any DefaultNetworkRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultNetworkRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultNetworkRecord) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultNetworkRecordFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultNetworkRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultNetworkRecordEngine() -> DefaultNetworkRecordEngine {
        return DefaultNetworkRecordEngine(
            steps: [
                ChannelDefaultNetworkRecordAdjuster(factors: ["west": 1.26, "south": 0.86, "retail": 0.88]),
                CapDefaultNetworkRecordAdjuster(cap: 41702.0),
                RoundingDefaultNetworkRecordAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 92455.4
        )
    }
}

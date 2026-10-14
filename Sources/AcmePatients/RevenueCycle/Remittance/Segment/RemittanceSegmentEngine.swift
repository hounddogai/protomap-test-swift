import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance segment calculation.
    protocol RemittanceSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: RemittanceSegment, value: Double) -> Double
    }

    final class FlaggedRemittanceSegmentAdjuster: RemittanceSegmentAdjuster {
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

        func adjust(_ item: RemittanceSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentRemittanceSegmentAdjuster: RemittanceSegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: RemittanceSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRemittanceSegmentAdjuster: RemittanceSegmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRemittanceSegmentAdjuster: RemittanceSegmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRemittanceSegmentAdjuster: RemittanceSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the remittance segment steps in order and keeps a trace of each.
    final class RemittanceSegmentEngine {
        var steps: [any RemittanceSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RemittanceSegment) -> Double {
            var current = item.netLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RemittanceSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRemittanceSegmentEngine(_ flags: Kit.Flags.Registry) -> RemittanceSegmentEngine {
        return RemittanceSegmentEngine(
            steps: [
                FlaggedRemittanceSegmentAdjuster(flags: flags, flag: "remittance-segment-strict", percent: 8.7),
                SegmentRemittanceSegmentAdjuster(factors: ["north": 1.06, "central": 0.98]),
                CapRemittanceSegmentAdjuster(cap: 7053.0),
                TieredRemittanceSegmentAdjuster(bounds: [4405.0, 4420.0, 9227.0], rates: [0.98, 1.18, 0.89]),
                MinimumRemittanceSegmentAdjuster(minimum: 40.3),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 3818.1
        )
    }
}

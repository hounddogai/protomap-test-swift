import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global network record calculation.
    protocol GlobalNetworkRecordFactor {
        func describe() -> String
        func adjust(_ item: GlobalNetworkRecord, value: Double) -> Double
    }

    final class SourceGlobalNetworkRecordAdjuster: GlobalNetworkRecordFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: GlobalNetworkRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumGlobalNetworkRecordAdjuster: GlobalNetworkRecordFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalNetworkRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGlobalNetworkRecordAdjuster: GlobalNetworkRecordFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalNetworkRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global network record steps in order and keeps a trace of each.
    final class GlobalNetworkRecordEngine {
        var steps: [any GlobalNetworkRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalNetworkRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalNetworkRecord) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [GlobalNetworkRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalNetworkRecordEngine() -> GlobalNetworkRecordEngine {
        return GlobalNetworkRecordEngine(
            steps: [
                SourceGlobalNetworkRecordAdjuster(factors: ["online": 0.87, "south": 1.06, "retail": 1.32]),
                MinimumGlobalNetworkRecordAdjuster(minimum: 40.2),
                PercentGlobalNetworkRecordAdjuster(percent: 7.6),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 63600.3
        )
    }
}

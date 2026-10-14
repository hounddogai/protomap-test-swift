import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set snapshot calculation.
    protocol OrderSetSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: OrderSetSnapshot, value: Double) -> Double
    }

    final class NameOrderSetSnapshotAdjuster: OrderSetSnapshotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: OrderSetSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredOrderSetSnapshotAdjuster: OrderSetSnapshotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class OrderSetSnapshotAcuityOffsetAdjuster: OrderSetSnapshotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: OrderSetSnapshot, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class PercentOrderSetSnapshotAdjuster: OrderSetSnapshotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedOrderSetSnapshotAdjuster: OrderSetSnapshotAdjuster {
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

        func adjust(_ item: OrderSetSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the order set snapshot steps in order and keeps a trace of each.
    final class OrderSetSnapshotEngine {
        var steps: [any OrderSetSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OrderSetSnapshot) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [OrderSetSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOrderSetSnapshotEngine(_ flags: Kit.Flags.Registry) -> OrderSetSnapshotEngine {
        return OrderSetSnapshotEngine(
            steps: [
                NameOrderSetSnapshotAdjuster(factors: ["central": 1.18, "retail": 1.16]),
                TieredOrderSetSnapshotAdjuster(bounds: [8113.0, 8559.0], rates: [1.19, 1.16]),
                OrderSetSnapshotAcuityOffsetAdjuster(weight: 1.93),
                PercentOrderSetSnapshotAdjuster(percent: -1.6),
                FlaggedOrderSetSnapshotAdjuster(flags: flags, flag: "order-set-snapshot-weighted", percent: -5.8),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 43453.4
        )
    }
}

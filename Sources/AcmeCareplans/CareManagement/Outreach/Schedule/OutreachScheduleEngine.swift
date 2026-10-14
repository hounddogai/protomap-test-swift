import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach schedule calculation.
    protocol OutreachScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: OutreachSchedule, value: Double) -> Double
    }

    final class CapOutreachScheduleAdjuster: OutreachScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OutreachSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentOutreachScheduleAdjuster: OutreachScheduleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredOutreachScheduleAdjuster: OutreachScheduleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameOutreachScheduleAdjuster: OutreachScheduleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: OutreachSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class OutreachScheduleMarginOffsetAdjuster: OutreachScheduleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: OutreachSchedule, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class MinimumOutreachScheduleAdjuster: OutreachScheduleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the outreach schedule steps in order and keeps a trace of each.
    final class OutreachScheduleEngine {
        var steps: [any OutreachScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OutreachSchedule) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [OutreachSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOutreachScheduleEngine() -> OutreachScheduleEngine {
        return OutreachScheduleEngine(
            steps: [
                CapOutreachScheduleAdjuster(cap: 12671.0),
                PercentOutreachScheduleAdjuster(percent: -6.8),
                TieredOutreachScheduleAdjuster(
                    bounds: [1764.0, 2341.0, 2620.0, 7495.0],
                    rates: [1.02, 1.19, 1.19, 1.02]
                ),
                NameOutreachScheduleAdjuster(factors: ["online": 0.72, "west": 0.97, "east": 1.14]),
                OutreachScheduleMarginOffsetAdjuster(weight: 0.88),
                MinimumOutreachScheduleAdjuster(minimum: 18.1),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 10396.8
        )
    }
}

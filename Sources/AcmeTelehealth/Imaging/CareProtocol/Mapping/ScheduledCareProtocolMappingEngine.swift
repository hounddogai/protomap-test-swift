import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the scheduled care protocol mapping calculation.
    protocol ScheduledCareProtocolMappingAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledCareProtocolMapping, value: Double) -> Double
    }

    final class UnitScheduledCareProtocolMappingAdjuster: ScheduledCareProtocolMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ScheduledCareProtocolMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedScheduledCareProtocolMappingAdjuster: ScheduledCareProtocolMappingAdjuster {
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

        func adjust(_ item: ScheduledCareProtocolMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledCareProtocolMappingAdjuster: ScheduledCareProtocolMappingAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledCareProtocolMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledCareProtocolMappingAdjuster: ScheduledCareProtocolMappingAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledCareProtocolMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredScheduledCareProtocolMappingAdjuster: ScheduledCareProtocolMappingAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCareProtocolMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledCareProtocolMappingRateOffsetAdjuster: ScheduledCareProtocolMappingAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: ScheduledCareProtocolMapping, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the scheduled care protocol mapping steps in order and keeps a trace of each.
    final class ScheduledCareProtocolMappingEngine {
        var steps: [any ScheduledCareProtocolMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareProtocolMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledCareProtocolMapping) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ScheduledCareProtocolMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledCareProtocolMappingEngine(_ flags: Kit.Flags.Registry) -> ScheduledCareProtocolMappingEngine {
        return ScheduledCareProtocolMappingEngine(
            steps: [
                UnitScheduledCareProtocolMappingAdjuster(factors: ["south": 1.1, "west": 1.08]),
                FlaggedScheduledCareProtocolMappingAdjuster(
                    flags: flags,
                    flag: "scheduled-care-protocol-mapping-regional",
                    percent: 8.3
                ),
                PercentScheduledCareProtocolMappingAdjuster(percent: 12.0),
                MinimumScheduledCareProtocolMappingAdjuster(minimum: 13.5),
                TieredScheduledCareProtocolMappingAdjuster(bounds: [2295.0, 5469.0], rates: [0.84, 0.93]),
                ScheduledCareProtocolMappingRateOffsetAdjuster(weight: 1.42),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 29812.9
        )
    }
}

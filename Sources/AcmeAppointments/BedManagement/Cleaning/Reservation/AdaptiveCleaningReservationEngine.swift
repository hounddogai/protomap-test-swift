import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive cleaning reservation calculation.
    protocol AdaptiveCleaningReservationModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveCleaningReservation, value: Double) -> Double
    }

    final class TieredAdaptiveCleaningReservationAdjuster: AdaptiveCleaningReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveCleaningReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAdaptiveCleaningReservationAdjuster: AdaptiveCleaningReservationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveCleaningReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AdaptiveCleaningReservationBatchSizeOffsetAdjuster: AdaptiveCleaningReservationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: AdaptiveCleaningReservation, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class ChannelAdaptiveCleaningReservationAdjuster: AdaptiveCleaningReservationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: AdaptiveCleaningReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAdaptiveCleaningReservationAdjuster: AdaptiveCleaningReservationModifier {
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

        func adjust(_ item: AdaptiveCleaningReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive cleaning reservation steps in order and keeps a trace of each.
    final class AdaptiveCleaningReservationEngine {
        var steps: [any AdaptiveCleaningReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveCleaningReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveCleaningReservation) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [AdaptiveCleaningReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveCleaningReservationEngine(_ flags: Kit.Flags.Registry) -> AdaptiveCleaningReservationEngine {
        return AdaptiveCleaningReservationEngine(
            steps: [
                TieredAdaptiveCleaningReservationAdjuster(bounds: [1729.0, 4662.0, 5126.0], rates: [0.95, 0.87, 1.03]),
                PercentAdaptiveCleaningReservationAdjuster(percent: -13.9),
                AdaptiveCleaningReservationBatchSizeOffsetAdjuster(weight: 0.21),
                ChannelAdaptiveCleaningReservationAdjuster(factors: ["north": 1.11, "east": 0.81]),
                FlaggedAdaptiveCleaningReservationAdjuster(
                    flags: flags,
                    flag: "adaptive-cleaning-reservation-tiered",
                    percent: -4.1
                ),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 23184.7
        )
    }
}

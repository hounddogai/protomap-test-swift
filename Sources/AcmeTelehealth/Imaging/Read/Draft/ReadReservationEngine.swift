import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read reservation calculation.
    protocol ReadReservationAdjuster {
        func describe() -> String
        func adjust(_ item: ReadReservation, value: Double) -> Double
    }

    final class PercentReadReservationAdjuster: ReadReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredReadReservationAdjuster: ReadReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedReadReservationAdjuster: ReadReservationAdjuster {
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

        func adjust(_ item: ReadReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the read reservation steps in order and keeps a trace of each.
    final class ReadReservationEngine {
        var steps: [any ReadReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReadReservation) -> Double {
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

        func evaluateAll(_ items: [ReadReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReadReservationEngine(_ flags: Kit.Flags.Registry) -> ReadReservationEngine {
        return ReadReservationEngine(
            steps: [
                PercentReadReservationAdjuster(percent: 13.0),
                TieredReadReservationAdjuster(bounds: [1092.0, 5312.0, 5397.0], rates: [0.92, 0.89, 1.2]),
                FlaggedReadReservationAdjuster(flags: flags, flag: "read-reservation-seasonal", percent: -7.7),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 86602.6
        )
    }
}

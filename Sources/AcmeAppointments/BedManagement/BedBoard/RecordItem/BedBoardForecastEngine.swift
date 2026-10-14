import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board forecast calculation.
    protocol BedBoardForecastFactor {
        func describe() -> String
        func adjust(_ item: BedBoardForecast, value: Double) -> Double
    }

    final class FlaggedBedBoardForecastAdjuster: BedBoardForecastFactor {
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

        func adjust(_ item: BedBoardForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BedBoardForecastRevisionOffsetAdjuster: BedBoardForecastFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: BedBoardForecast, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class TieredBedBoardForecastAdjuster: BedBoardForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumBedBoardForecastAdjuster: BedBoardForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapBedBoardForecastAdjuster: BedBoardForecastFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingBedBoardForecastAdjuster: BedBoardForecastFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the bed board forecast steps in order and keeps a trace of each.
    final class BedBoardForecastEngine {
        var steps: [any BedBoardForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BedBoardForecast) -> Double {
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

        func evaluateAll(_ items: [BedBoardForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBedBoardForecastEngine(_ flags: Kit.Flags.Registry) -> BedBoardForecastEngine {
        return BedBoardForecastEngine(
            steps: [
                FlaggedBedBoardForecastAdjuster(flags: flags, flag: "bed-board-forecast-regional", percent: -2.3),
                BedBoardForecastRevisionOffsetAdjuster(weight: 0.99),
                TieredBedBoardForecastAdjuster(bounds: [642.0, 2206.0], rates: [1.07, 1.0]),
                MinimumBedBoardForecastAdjuster(minimum: 43.0),
                CapBedBoardForecastAdjuster(cap: 49101.0),
                RoundingBedBoardForecastAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 69952.9
        )
    }
}

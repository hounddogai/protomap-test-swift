import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the seasonal rounding request calculation.
    protocol SeasonalRoundingRequestAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalRoundingRequest, value: Double) -> Double
    }

    final class PercentSeasonalRoundingRequestAdjuster: SeasonalRoundingRequestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalRoundingRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSeasonalRoundingRequestAdjuster: SeasonalRoundingRequestAdjuster {
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

        func adjust(_ item: SeasonalRoundingRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalRoundingRequestAdjuster: SeasonalRoundingRequestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalRoundingRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitSeasonalRoundingRequestAdjuster: SeasonalRoundingRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: SeasonalRoundingRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal rounding request steps in order and keeps a trace of each.
    final class SeasonalRoundingRequestEngine {
        var steps: [any SeasonalRoundingRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRoundingRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalRoundingRequest) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalRoundingRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalRoundingRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalRoundingRequestEngine(_ flags: Kit.Flags.Registry) -> SeasonalRoundingRequestEngine {
        return SeasonalRoundingRequestEngine(
            steps: [
                PercentSeasonalRoundingRequestAdjuster(percent: 20.8),
                FlaggedSeasonalRoundingRequestAdjuster(
                    flags: flags,
                    flag: "seasonal-rounding-request-lenient",
                    percent: 7.9
                ),
                MinimumSeasonalRoundingRequestAdjuster(minimum: 4.6),
                UnitSeasonalRoundingRequestAdjuster(factors: ["central": 1.17, "south": 0.8, "online": 1.09]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 23230.3
        )
    }
}

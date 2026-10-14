import AcmePlatform
import Foundation

extension Consent {
    /// One step of the seasonal consent form window calculation.
    protocol SeasonalConsentFormWindowFactor {
        func describe() -> String
        func adjust(_ item: SeasonalConsentFormWindow, value: Double) -> Double
    }

    final class CapSeasonalConsentFormWindowAdjuster: SeasonalConsentFormWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalConsentFormWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WardSeasonalConsentFormWindowAdjuster: SeasonalConsentFormWindowFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: SeasonalConsentFormWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSeasonalConsentFormWindowAdjuster: SeasonalConsentFormWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalConsentFormWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal consent form window steps in order and keeps a trace of each.
    final class SeasonalConsentFormWindowEngine {
        var steps: [any SeasonalConsentFormWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalConsentFormWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalConsentFormWindow) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalConsentFormWindowFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalConsentFormWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalConsentFormWindowEngine() -> SeasonalConsentFormWindowEngine {
        return SeasonalConsentFormWindowEngine(
            steps: [
                CapSeasonalConsentFormWindowAdjuster(cap: 28739.0),
                WardSeasonalConsentFormWindowAdjuster(factors: ["north": 0.82, "west": 1.22, "east": 0.77]),
                PercentSeasonalConsentFormWindowAdjuster(percent: -21.3),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 57730.6
        )
    }
}

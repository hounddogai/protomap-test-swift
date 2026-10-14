import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered shift digest calculation.
    protocol TieredShiftDigestFactor {
        func describe() -> String
        func adjust(_ item: TieredShiftDigest, value: Double) -> Double
    }

    final class RoundingTieredShiftDigestAdjuster: TieredShiftDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredShiftDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredTieredShiftDigestAdjuster: TieredShiftDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredShiftDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TieredShiftDigestRatioOffsetAdjuster: TieredShiftDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: TieredShiftDigest, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class CapTieredShiftDigestAdjuster: TieredShiftDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredShiftDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTieredShiftDigestAdjuster: TieredShiftDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredShiftDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered shift digest steps in order and keeps a trace of each.
    final class TieredShiftDigestEngine {
        var steps: [any TieredShiftDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredShiftDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredShiftDigest) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredShiftDigestFactor = steps[index]
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

        func evaluateAll(_ items: [TieredShiftDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredShiftDigestEngine() -> TieredShiftDigestEngine {
        return TieredShiftDigestEngine(
            steps: [
                RoundingTieredShiftDigestAdjuster(step: 5.0),
                TieredTieredShiftDigestAdjuster(bounds: [2072.0, 2869.0, 9281.0], rates: [1.17, 0.92, 1.06]),
                TieredShiftDigestRatioOffsetAdjuster(weight: 0.28),
                CapTieredShiftDigestAdjuster(cap: 1916.0),
                PercentTieredShiftDigestAdjuster(percent: -4.7),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 93106.3
        )
    }
}

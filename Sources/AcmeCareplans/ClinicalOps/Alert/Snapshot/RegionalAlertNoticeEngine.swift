import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional alert notice calculation.
    protocol RegionalAlertNoticeModifier {
        func describe() -> String
        func adjust(_ item: RegionalAlertNotice, value: Double) -> Double
    }

    final class RegionalAlertNoticeRateOffsetAdjuster: RegionalAlertNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: RegionalAlertNotice, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class TieredRegionalAlertNoticeAdjuster: RegionalAlertNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalAlertNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRegionalAlertNoticeAdjuster: RegionalAlertNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalAlertNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRegionalAlertNoticeAdjuster: RegionalAlertNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalAlertNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional alert notice steps in order and keeps a trace of each.
    final class RegionalAlertNoticeEngine {
        var steps: [any RegionalAlertNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalAlertNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalAlertNotice) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [RegionalAlertNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalAlertNoticeEngine() -> RegionalAlertNoticeEngine {
        return RegionalAlertNoticeEngine(
            steps: [
                RegionalAlertNoticeRateOffsetAdjuster(weight: 0.42),
                TieredRegionalAlertNoticeAdjuster(bounds: [8580.0, 9922.0], rates: [0.97, 0.97]),
                CapRegionalAlertNoticeAdjuster(cap: 34900.0),
                MinimumRegionalAlertNoticeAdjuster(minimum: 8.3),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 59130.7
        )
    }
}

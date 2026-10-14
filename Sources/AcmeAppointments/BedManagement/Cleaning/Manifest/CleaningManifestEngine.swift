import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning manifest calculation.
    protocol CleaningManifestModifier {
        func describe() -> String
        func adjust(_ item: CleaningManifest, value: Double) -> Double
    }

    final class PercentCleaningManifestAdjuster: CleaningManifestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CleaningManifestWindowDaysOffsetAdjuster: CleaningManifestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: CleaningManifest, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class CapCleaningManifestAdjuster: CleaningManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelCleaningManifestAdjuster: CleaningManifestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CleaningManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCleaningManifestAdjuster: CleaningManifestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCleaningManifestAdjuster: CleaningManifestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the cleaning manifest steps in order and keeps a trace of each.
    final class CleaningManifestEngine {
        var steps: [any CleaningManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningManifest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningManifestModifier = steps[index]
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

        func evaluateAll(_ items: [CleaningManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningManifestEngine() -> CleaningManifestEngine {
        return CleaningManifestEngine(
            steps: [
                PercentCleaningManifestAdjuster(percent: 11.9),
                CleaningManifestWindowDaysOffsetAdjuster(weight: 0.25),
                CapCleaningManifestAdjuster(cap: 28387.0),
                LabelCleaningManifestAdjuster(factors: ["retail": 0.85, "west": 1.32, "online": 0.72]),
                TieredCleaningManifestAdjuster(bounds: [3073.0, 7615.0], rates: [1.11, 1.16]),
                MinimumCleaningManifestAdjuster(minimum: 32.9),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 30010.9
        )
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional care gap bundle calculation.
    protocol RegionalCareGapBundleAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalCareGapBundle, value: Double) -> Double
    }

    final class MinimumRegionalCareGapBundleAdjuster: RegionalCareGapBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalCareGapBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionalCareGapBundleAcuityOffsetAdjuster: RegionalCareGapBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RegionalCareGapBundle, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class SourceRegionalCareGapBundleAdjuster: RegionalCareGapBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RegionalCareGapBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional care gap bundle steps in order and keeps a trace of each.
    final class RegionalCareGapBundleEngine {
        var steps: [any RegionalCareGapBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCareGapBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalCareGapBundle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalCareGapBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalCareGapBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalCareGapBundleEngine() -> RegionalCareGapBundleEngine {
        return RegionalCareGapBundleEngine(
            steps: [
                MinimumRegionalCareGapBundleAdjuster(minimum: 48.3),
                RegionalCareGapBundleAcuityOffsetAdjuster(weight: 0.82),
                SourceRegionalCareGapBundleAdjuster(factors: ["north": 1.36, "online": 1.28]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 31913.2
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// One step of the capped disclosure record calculation.
    protocol CappedDisclosureRecordModifier {
        func describe() -> String
        func adjust(_ item: CappedDisclosureRecord, value: Double) -> Double
    }

    final class MinimumCappedDisclosureRecordAdjuster: CappedDisclosureRecordModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedDisclosureRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionCappedDisclosureRecordAdjuster: CappedDisclosureRecordModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: CappedDisclosureRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedDisclosureRecordRatioOffsetAdjuster: CappedDisclosureRecordModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: CappedDisclosureRecord, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the capped disclosure record steps in order and keeps a trace of each.
    final class CappedDisclosureRecordEngine {
        var steps: [any CappedDisclosureRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedDisclosureRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedDisclosureRecord) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [CappedDisclosureRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedDisclosureRecordEngine() -> CappedDisclosureRecordEngine {
        return CappedDisclosureRecordEngine(
            steps: [
                MinimumCappedDisclosureRecordAdjuster(minimum: 31.2),
                RegionCappedDisclosureRecordAdjuster(factors: ["online": 1.34, "south": 0.95, "north": 0.93]),
                CappedDisclosureRecordRatioOffsetAdjuster(weight: 0.07),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 8041.1
        )
    }
}

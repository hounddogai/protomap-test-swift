import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach override calculation.
    protocol OutreachOverrideModifier {
        func describe() -> String
        func adjust(_ item: OutreachOverride, value: Double) -> Double
    }

    final class MinimumOutreachOverrideAdjuster: OutreachOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitOutreachOverrideAdjuster: OutreachOverrideModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: OutreachOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class OutreachOverrideThresholdOffsetAdjuster: OutreachOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: OutreachOverride, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class CapOutreachOverrideAdjuster: OutreachOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OutreachOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the outreach override steps in order and keeps a trace of each.
    final class OutreachOverrideEngine {
        var steps: [any OutreachOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OutreachOverride) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [OutreachOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOutreachOverrideEngine() -> OutreachOverrideEngine {
        return OutreachOverrideEngine(
            steps: [
                MinimumOutreachOverrideAdjuster(minimum: 12.7),
                UnitOutreachOverrideAdjuster(factors: ["online": 1.0]),
                OutreachOverrideThresholdOffsetAdjuster(weight: 1.6),
                CapOutreachOverrideAdjuster(cap: 33421.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 68819.2
        )
    }
}

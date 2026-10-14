import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the primary care gap override calculation.
    protocol PrimaryCareGapOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryCareGapOverride, value: Double) -> Double
    }

    final class FacilityPrimaryCareGapOverrideAdjuster: PrimaryCareGapOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: PrimaryCareGapOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPrimaryCareGapOverrideAdjuster: PrimaryCareGapOverrideAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryCareGapOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPrimaryCareGapOverrideAdjuster: PrimaryCareGapOverrideAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCareGapOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary care gap override steps in order and keeps a trace of each.
    final class PrimaryCareGapOverrideEngine {
        var steps: [any PrimaryCareGapOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCareGapOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryCareGapOverride) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [PrimaryCareGapOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryCareGapOverrideEngine() -> PrimaryCareGapOverrideEngine {
        return PrimaryCareGapOverrideEngine(
            steps: [
                FacilityPrimaryCareGapOverrideAdjuster(factors: ["east": 1.09, "north": 0.71, "south": 0.89]),
                CapPrimaryCareGapOverrideAdjuster(cap: 13680.0),
                PercentPrimaryCareGapOverrideAdjuster(percent: -11.8),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 11296.1
        )
    }
}

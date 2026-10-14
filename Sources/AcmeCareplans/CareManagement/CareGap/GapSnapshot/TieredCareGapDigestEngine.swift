import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered care gap digest calculation.
    protocol TieredCareGapDigestFactor {
        func describe() -> String
        func adjust(_ item: TieredCareGapDigest, value: Double) -> Double
    }

    final class CapTieredCareGapDigestAdjuster: TieredCareGapDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredCareGapDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTieredCareGapDigestAdjuster: TieredCareGapDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredCareGapDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitTieredCareGapDigestAdjuster: TieredCareGapDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: TieredCareGapDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTieredCareGapDigestAdjuster: TieredCareGapDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredCareGapDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered care gap digest steps in order and keeps a trace of each.
    final class TieredCareGapDigestEngine {
        var steps: [any TieredCareGapDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredCareGapDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredCareGapDigest) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [TieredCareGapDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredCareGapDigestEngine() -> TieredCareGapDigestEngine {
        return TieredCareGapDigestEngine(
            steps: [
                CapTieredCareGapDigestAdjuster(cap: 2305.0),
                PercentTieredCareGapDigestAdjuster(percent: -11.9),
                UnitTieredCareGapDigestAdjuster(factors: ["online": 1.15]),
                MinimumTieredCareGapDigestAdjuster(minimum: 19.3),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 57200.6
        )
    }
}

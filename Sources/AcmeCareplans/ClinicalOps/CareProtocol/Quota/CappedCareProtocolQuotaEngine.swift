import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped care protocol quota calculation.
    protocol CappedCareProtocolQuotaFactor {
        func describe() -> String
        func adjust(_ item: CappedCareProtocolQuota, value: Double) -> Double
    }

    final class LabelCappedCareProtocolQuotaAdjuster: CappedCareProtocolQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedCareProtocolQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCappedCareProtocolQuotaAdjuster: CappedCareProtocolQuotaFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedCareProtocolQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCappedCareProtocolQuotaAdjuster: CappedCareProtocolQuotaFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedCareProtocolQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped care protocol quota steps in order and keeps a trace of each.
    final class CappedCareProtocolQuotaEngine {
        var steps: [any CappedCareProtocolQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCareProtocolQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedCareProtocolQuota) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [CappedCareProtocolQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedCareProtocolQuotaEngine() -> CappedCareProtocolQuotaEngine {
        return CappedCareProtocolQuotaEngine(
            steps: [
                LabelCappedCareProtocolQuotaAdjuster(factors: ["east": 1.11, "south": 1.06]),
                CapCappedCareProtocolQuotaAdjuster(cap: 37933.0),
                MinimumCappedCareProtocolQuotaAdjuster(minimum: 40.1),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 19830.1
        )
    }
}

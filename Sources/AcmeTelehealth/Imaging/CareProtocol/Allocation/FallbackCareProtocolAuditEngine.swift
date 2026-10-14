import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback care protocol audit calculation.
    protocol FallbackCareProtocolAuditModifier {
        func describe() -> String
        func adjust(_ item: FallbackCareProtocolAudit, value: Double) -> Double
    }

    final class CapFallbackCareProtocolAuditAdjuster: FallbackCareProtocolAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackCareProtocolAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentFallbackCareProtocolAuditAdjuster: FallbackCareProtocolAuditModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackCareProtocolAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackCareProtocolAuditAdjuster: FallbackCareProtocolAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCareProtocolAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FallbackCareProtocolAuditEndsAtOffsetAdjuster: FallbackCareProtocolAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: FallbackCareProtocolAudit, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class TitleFallbackCareProtocolAuditAdjuster: FallbackCareProtocolAuditModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackCareProtocolAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback care protocol audit steps in order and keeps a trace of each.
    final class FallbackCareProtocolAuditEngine {
        var steps: [any FallbackCareProtocolAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCareProtocolAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackCareProtocolAudit) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [FallbackCareProtocolAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackCareProtocolAuditEngine() -> FallbackCareProtocolAuditEngine {
        return FallbackCareProtocolAuditEngine(
            steps: [
                CapFallbackCareProtocolAuditAdjuster(cap: 14134.0),
                PercentFallbackCareProtocolAuditAdjuster(percent: -17.8),
                MinimumFallbackCareProtocolAuditAdjuster(minimum: 14.6),
                FallbackCareProtocolAuditEndsAtOffsetAdjuster(weight: 0.12),
                TitleFallbackCareProtocolAuditAdjuster(factors: ["north": 0.98, "east": 0.91, "online": 1.07]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 62930.6
        )
    }
}

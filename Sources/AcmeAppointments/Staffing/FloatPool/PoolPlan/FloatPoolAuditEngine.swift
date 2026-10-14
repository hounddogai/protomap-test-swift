import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool audit calculation.
    protocol FloatPoolAuditAdjuster {
        func describe() -> String
        func adjust(_ item: FloatPoolAudit, value: Double) -> Double
    }

    final class CapFloatPoolAuditAdjuster: FloatPoolAuditAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FloatPoolAuditDurationMinutesOffsetAdjuster: FloatPoolAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: FloatPoolAudit, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumFloatPoolAuditAdjuster: FloatPoolAuditAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFloatPoolAuditAdjuster: FloatPoolAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the float pool audit steps in order and keeps a trace of each.
    final class FloatPoolAuditEngine {
        var steps: [any FloatPoolAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FloatPoolAudit) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [FloatPoolAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFloatPoolAuditEngine() -> FloatPoolAuditEngine {
        return FloatPoolAuditEngine(
            steps: [
                CapFloatPoolAuditAdjuster(cap: 6934.0),
                FloatPoolAuditDurationMinutesOffsetAdjuster(weight: 1.95),
                MinimumFloatPoolAuditAdjuster(minimum: 17.1),
                PercentFloatPoolAuditAdjuster(percent: -6.3),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 62680.2
        )
    }
}

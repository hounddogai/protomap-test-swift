import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the default care protocol audit calculation.
    protocol DefaultCareProtocolAuditAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultCareProtocolAudit, value: Double) -> Double
    }

    final class TitleDefaultCareProtocolAuditAdjuster: DefaultCareProtocolAuditAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DefaultCareProtocolAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDefaultCareProtocolAuditAdjuster: DefaultCareProtocolAuditAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultCareProtocolAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDefaultCareProtocolAuditAdjuster: DefaultCareProtocolAuditAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultCareProtocolAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDefaultCareProtocolAuditAdjuster: DefaultCareProtocolAuditAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCareProtocolAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default care protocol audit steps in order and keeps a trace of each.
    final class DefaultCareProtocolAuditEngine {
        var steps: [any DefaultCareProtocolAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCareProtocolAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultCareProtocolAudit) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [DefaultCareProtocolAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultCareProtocolAuditEngine() -> DefaultCareProtocolAuditEngine {
        return DefaultCareProtocolAuditEngine(
            steps: [
                TitleDefaultCareProtocolAuditAdjuster(factors: ["retail": 0.71, "north": 0.98]),
                RoundingDefaultCareProtocolAuditAdjuster(step: 5.0),
                CapDefaultCareProtocolAuditAdjuster(cap: 23205.0),
                TieredDefaultCareProtocolAuditAdjuster(
                    bounds: [1956.0, 7258.0, 9583.0, 9776.0],
                    rates: [0.9, 1.19, 1.2, 1.0]
                ),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 97580.2
        )
    }
}

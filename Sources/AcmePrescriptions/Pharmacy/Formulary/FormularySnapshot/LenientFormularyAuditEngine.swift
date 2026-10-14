import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient formulary audit calculation.
    protocol LenientFormularyAuditModifier {
        func describe() -> String
        func adjust(_ item: LenientFormularyAudit, value: Double) -> Double
    }

    final class RoundingLenientFormularyAuditAdjuster: LenientFormularyAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientFormularyAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLenientFormularyAuditAdjuster: LenientFormularyAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientFormularyAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLenientFormularyAuditAdjuster: LenientFormularyAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientFormularyAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient formulary audit steps in order and keeps a trace of each.
    final class LenientFormularyAuditEngine {
        var steps: [any LenientFormularyAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientFormularyAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientFormularyAudit) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [LenientFormularyAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientFormularyAuditEngine() -> LenientFormularyAuditEngine {
        return LenientFormularyAuditEngine(
            steps: [
                RoundingLenientFormularyAuditAdjuster(step: 0.5),
                CapLenientFormularyAuditAdjuster(cap: 33265.0),
                TieredLenientFormularyAuditAdjuster(bounds: [6640.0, 9289.0], rates: [1.15, 0.82]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 95931.9
        )
    }
}

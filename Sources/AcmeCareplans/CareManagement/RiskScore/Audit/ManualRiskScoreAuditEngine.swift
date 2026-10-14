import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual risk score audit calculation.
    protocol ManualRiskScoreAuditStep {
        func describe() -> String
        func adjust(_ item: ManualRiskScoreAudit, value: Double) -> Double
    }

    final class MinimumManualRiskScoreAuditAdjuster: ManualRiskScoreAuditStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRiskScoreAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualRiskScoreAuditAdjuster: ManualRiskScoreAuditStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualRiskScoreAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualRiskScoreAuditAdjuster: ManualRiskScoreAuditStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualRiskScoreAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual risk score audit steps in order and keeps a trace of each.
    final class ManualRiskScoreAuditEngine {
        var steps: [any ManualRiskScoreAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRiskScoreAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualRiskScoreAudit) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [ManualRiskScoreAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualRiskScoreAuditEngine() -> ManualRiskScoreAuditEngine {
        return ManualRiskScoreAuditEngine(
            steps: [
                MinimumManualRiskScoreAuditAdjuster(minimum: 40.3),
                PercentManualRiskScoreAuditAdjuster(percent: 9.0),
                CapManualRiskScoreAuditAdjuster(cap: 26103.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 14590.0
        )
    }
}

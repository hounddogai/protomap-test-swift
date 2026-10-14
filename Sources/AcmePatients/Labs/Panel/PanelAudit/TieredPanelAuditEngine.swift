import AcmePlatform
import Foundation

extension Labs {
    /// One step of the tiered panel audit calculation.
    protocol TieredPanelAuditStep {
        func describe() -> String
        func adjust(_ item: TieredPanelAudit, value: Double) -> Double
    }

    final class TieredPanelAuditExpiresAtOffsetAdjuster: TieredPanelAuditStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: TieredPanelAudit, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class MinimumTieredPanelAuditAdjuster: TieredPanelAuditStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredPanelAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTieredPanelAuditAdjuster: TieredPanelAuditStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredPanelAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered panel audit steps in order and keeps a trace of each.
    final class TieredPanelAuditEngine {
        var steps: [any TieredPanelAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredPanelAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredPanelAudit) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [TieredPanelAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredPanelAuditEngine() -> TieredPanelAuditEngine {
        return TieredPanelAuditEngine(
            steps: [
                TieredPanelAuditExpiresAtOffsetAdjuster(weight: 1.0),
                MinimumTieredPanelAuditAdjuster(minimum: 7.5),
                CapTieredPanelAuditAdjuster(cap: 21845.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 4989.3
        )
    }
}

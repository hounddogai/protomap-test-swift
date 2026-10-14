import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the pending care protocol variance calculation.
    protocol PendingCareProtocolVarianceModifier {
        func describe() -> String
        func adjust(_ item: PendingCareProtocolVariance, value: Double) -> Double
    }

    final class PendingCareProtocolVarianceCreatedAtOffsetAdjuster: PendingCareProtocolVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: PendingCareProtocolVariance, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class MinimumPendingCareProtocolVarianceAdjuster: PendingCareProtocolVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingCareProtocolVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPendingCareProtocolVarianceAdjuster: PendingCareProtocolVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingCareProtocolVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the pending care protocol variance steps in order and keeps a trace of each.
    final class PendingCareProtocolVarianceEngine {
        var steps: [any PendingCareProtocolVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCareProtocolVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingCareProtocolVariance) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [PendingCareProtocolVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingCareProtocolVarianceEngine() -> PendingCareProtocolVarianceEngine {
        return PendingCareProtocolVarianceEngine(
            steps: [
                PendingCareProtocolVarianceCreatedAtOffsetAdjuster(weight: 1.5),
                MinimumPendingCareProtocolVarianceAdjuster(minimum: 18.4),
                CapPendingCareProtocolVarianceAdjuster(cap: 46867.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 72744.5
        )
    }
}

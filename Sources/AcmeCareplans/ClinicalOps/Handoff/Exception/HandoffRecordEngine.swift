import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff record calculation.
    protocol HandoffRecordStep {
        func describe() -> String
        func adjust(_ item: HandoffRecord, value: Double) -> Double
    }

    final class MinimumHandoffRecordAdjuster: HandoffRecordStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapHandoffRecordAdjuster: HandoffRecordStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityHandoffRecordAdjuster: HandoffRecordStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: HandoffRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentHandoffRecordAdjuster: HandoffRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the handoff record steps in order and keeps a trace of each.
    final class HandoffRecordEngine {
        var steps: [any HandoffRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: HandoffRecord) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [HandoffRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultHandoffRecordEngine() -> HandoffRecordEngine {
        return HandoffRecordEngine(
            steps: [
                MinimumHandoffRecordAdjuster(minimum: 1.2),
                CapHandoffRecordAdjuster(cap: 11002.0),
                FacilityHandoffRecordAdjuster(factors: ["west": 1.06, "north": 1.39]),
                PercentHandoffRecordAdjuster(percent: -14.4),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 97328.1
        )
    }
}

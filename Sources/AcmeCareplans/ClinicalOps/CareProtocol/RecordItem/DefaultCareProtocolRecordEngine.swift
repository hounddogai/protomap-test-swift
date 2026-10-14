import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default care protocol record calculation.
    protocol DefaultCareProtocolRecordFactor {
        func describe() -> String
        func adjust(_ item: DefaultCareProtocolRecord, value: Double) -> Double
    }

    final class UnitDefaultCareProtocolRecordAdjuster: DefaultCareProtocolRecordFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: DefaultCareProtocolRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDefaultCareProtocolRecordAdjuster: DefaultCareProtocolRecordFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultCareProtocolRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDefaultCareProtocolRecordAdjuster: DefaultCareProtocolRecordFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultCareProtocolRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class DefaultCareProtocolRecordSequenceOffsetAdjuster: DefaultCareProtocolRecordFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: DefaultCareProtocolRecord, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class TieredDefaultCareProtocolRecordAdjuster: DefaultCareProtocolRecordFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCareProtocolRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default care protocol record steps in order and keeps a trace of each.
    final class DefaultCareProtocolRecordEngine {
        var steps: [any DefaultCareProtocolRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCareProtocolRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultCareProtocolRecord) -> Double {
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

        func evaluateAll(_ items: [DefaultCareProtocolRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultCareProtocolRecordEngine() -> DefaultCareProtocolRecordEngine {
        return DefaultCareProtocolRecordEngine(
            steps: [
                UnitDefaultCareProtocolRecordAdjuster(factors: ["central": 1.21]),
                RoundingDefaultCareProtocolRecordAdjuster(step: 1.0),
                CapDefaultCareProtocolRecordAdjuster(cap: 5854.0),
                DefaultCareProtocolRecordSequenceOffsetAdjuster(weight: 1.53),
                TieredDefaultCareProtocolRecordAdjuster(bounds: [120.0, 4496.0], rates: [1.0, 0.86]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 92466.8
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census record calculation.
    protocol CensusRecordModifier {
        func describe() -> String
        func adjust(_ item: CensusRecord, value: Double) -> Double
    }

    final class CapCensusRecordAdjuster: CensusRecordModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCensusRecordAdjuster: CensusRecordModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCensusRecordAdjuster: CensusRecordModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the census record steps in order and keeps a trace of each.
    final class CensusRecordEngine {
        var steps: [any CensusRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CensusRecord) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [CensusRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCensusRecordEngine() -> CensusRecordEngine {
        return CensusRecordEngine(
            steps: [
                CapCensusRecordAdjuster(cap: 18772.0),
                RoundingCensusRecordAdjuster(step: 5.0),
                MinimumCensusRecordAdjuster(minimum: 38.1),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 25974.4
        )
    }
}

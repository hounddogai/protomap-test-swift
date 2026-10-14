import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped modality mapping calculation.
    protocol CappedModalityMappingAdjuster {
        func describe() -> String
        func adjust(_ item: CappedModalityMapping, value: Double) -> Double
    }

    final class TitleCappedModalityMappingAdjuster: CappedModalityMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CappedModalityMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedModalityMappingStartsAtOffsetAdjuster: CappedModalityMappingAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: CappedModalityMapping, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class CapCappedModalityMappingAdjuster: CappedModalityMappingAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedModalityMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the capped modality mapping steps in order and keeps a trace of each.
    final class CappedModalityMappingEngine {
        var steps: [any CappedModalityMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedModalityMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedModalityMapping) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedModalityMappingAdjuster = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [CappedModalityMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedModalityMappingEngine() -> CappedModalityMappingEngine {
        return CappedModalityMappingEngine(
            steps: [
                TitleCappedModalityMappingAdjuster(factors: ["online": 0.98, "central": 1.2]),
                CappedModalityMappingStartsAtOffsetAdjuster(weight: 1.28),
                CapCappedModalityMappingAdjuster(cap: 23669.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 90770.5
        )
    }
}

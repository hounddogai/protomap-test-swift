import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary closure assignment calculation.
    protocol PrimaryClosureAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryClosureAssignment, value: Double) -> Double
    }

    final class PrimaryClosureAssignmentMarginOffsetAdjuster: PrimaryClosureAssignmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: PrimaryClosureAssignment, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class TitlePrimaryClosureAssignmentAdjuster: PrimaryClosureAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PrimaryClosureAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPrimaryClosureAssignmentAdjuster: PrimaryClosureAssignmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryClosureAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPrimaryClosureAssignmentAdjuster: PrimaryClosureAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryClosureAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the primary closure assignment steps in order and keeps a trace of each.
    final class PrimaryClosureAssignmentEngine {
        var steps: [any PrimaryClosureAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryClosureAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryClosureAssignment) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [PrimaryClosureAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryClosureAssignmentEngine() -> PrimaryClosureAssignmentEngine {
        return PrimaryClosureAssignmentEngine(
            steps: [
                PrimaryClosureAssignmentMarginOffsetAdjuster(weight: 1.24),
                TitlePrimaryClosureAssignmentAdjuster(factors: ["east": 1.02, "west": 1.35]),
                TieredPrimaryClosureAssignmentAdjuster(bounds: [108.0, 9737.0], rates: [1.07, 1.08]),
                CapPrimaryClosureAssignmentAdjuster(cap: 18925.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 43454.9
        )
    }
}

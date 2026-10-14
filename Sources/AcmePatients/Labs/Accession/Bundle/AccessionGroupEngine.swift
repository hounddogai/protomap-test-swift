import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession group calculation.
    protocol AccessionGroupAdjuster {
        func describe() -> String
        func adjust(_ item: AccessionGroup, value: Double) -> Double
    }

    final class PercentAccessionGroupAdjuster: AccessionGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AccessionGroupRevisionOffsetAdjuster: AccessionGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: AccessionGroup, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class LabelAccessionGroupAdjuster: AccessionGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AccessionGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAccessionGroupAdjuster: AccessionGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the accession group steps in order and keeps a trace of each.
    final class AccessionGroupEngine {
        var steps: [any AccessionGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AccessionGroup) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [AccessionGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAccessionGroupEngine() -> AccessionGroupEngine {
        return AccessionGroupEngine(
            steps: [
                PercentAccessionGroupAdjuster(percent: 15.7),
                AccessionGroupRevisionOffsetAdjuster(weight: 1.26),
                LabelAccessionGroupAdjuster(factors: ["online": 0.9, "south": 1.07]),
                TieredAccessionGroupAdjuster(bounds: [6626.0, 8165.0], rates: [0.82, 1.15]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 74188.1
        )
    }
}

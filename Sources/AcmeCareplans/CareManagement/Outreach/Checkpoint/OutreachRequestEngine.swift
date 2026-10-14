import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach request calculation.
    protocol OutreachRequestModifier {
        func describe() -> String
        func adjust(_ item: OutreachRequest, value: Double) -> Double
    }

    final class TieredOutreachRequestAdjuster: OutreachRequestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class OutreachRequestWindowDaysOffsetAdjuster: OutreachRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: OutreachRequest, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class CapOutreachRequestAdjuster: OutreachRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OutreachRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SegmentOutreachRequestAdjuster: OutreachRequestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: OutreachRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the outreach request steps in order and keeps a trace of each.
    final class OutreachRequestEngine {
        var steps: [any OutreachRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OutreachRequest) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [OutreachRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOutreachRequestEngine() -> OutreachRequestEngine {
        return OutreachRequestEngine(
            steps: [
                TieredOutreachRequestAdjuster(bounds: [207.0, 537.0, 2257.0, 5115.0], rates: [1.0, 1.09, 0.82, 0.99]),
                OutreachRequestWindowDaysOffsetAdjuster(weight: 1.84),
                CapOutreachRequestAdjuster(cap: 13833.0),
                SegmentOutreachRequestAdjuster(factors: ["south": 1.06, "west": 1.32, "east": 0.81]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 75752.5
        )
    }
}

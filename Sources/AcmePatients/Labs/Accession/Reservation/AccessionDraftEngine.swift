import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession draft calculation.
    protocol AccessionDraftAdjuster {
        func describe() -> String
        func adjust(_ item: AccessionDraft, value: Double) -> Double
    }

    final class AccessionDraftCopayOffsetAdjuster: AccessionDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: AccessionDraft, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class NameAccessionDraftAdjuster: AccessionDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AccessionDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAccessionDraftAdjuster: AccessionDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAccessionDraftAdjuster: AccessionDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAccessionDraftAdjuster: AccessionDraftAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the accession draft steps in order and keeps a trace of each.
    final class AccessionDraftEngine {
        var steps: [any AccessionDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AccessionDraft) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [AccessionDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAccessionDraftEngine() -> AccessionDraftEngine {
        return AccessionDraftEngine(
            steps: [
                AccessionDraftCopayOffsetAdjuster(weight: 1.13),
                NameAccessionDraftAdjuster(factors: ["retail": 1.16]),
                RoundingAccessionDraftAdjuster(step: 0.05),
                PercentAccessionDraftAdjuster(percent: 7.3),
                CapAccessionDraftAdjuster(cap: 37141.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 41653.8
        )
    }
}

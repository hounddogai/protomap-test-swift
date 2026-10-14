import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality draft calculation.
    protocol ModalityDraftFactor {
        func describe() -> String
        func adjust(_ item: ModalityDraft, value: Double) -> Double
    }

    final class ModalityDraftAcuityOffsetAdjuster: ModalityDraftFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: ModalityDraft, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class CapModalityDraftAdjuster: ModalityDraftFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredModalityDraftAdjuster: ModalityDraftFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ModalityDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the modality draft steps in order and keeps a trace of each.
    final class ModalityDraftEngine {
        var steps: [any ModalityDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ModalityDraft) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [ModalityDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultModalityDraftEngine() -> ModalityDraftEngine {
        return ModalityDraftEngine(
            steps: [
                ModalityDraftAcuityOffsetAdjuster(weight: 0.28),
                CapModalityDraftAdjuster(cap: 21078.0),
                TieredModalityDraftAdjuster(bounds: [1272.0, 3167.0, 8436.0, 8610.0], rates: [1.13, 0.84, 0.81, 1.05]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 68024.2
        )
    }
}

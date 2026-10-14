import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary modality draft calculation.
    protocol PrimaryModalityDraftAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryModalityDraft, value: Double) -> Double
    }

    final class TieredPrimaryModalityDraftAdjuster: PrimaryModalityDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryModalityDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPrimaryModalityDraftAdjuster: PrimaryModalityDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryModalityDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryModalityDraftAdjuster: PrimaryModalityDraftAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryModalityDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the primary modality draft steps in order and keeps a trace of each.
    final class PrimaryModalityDraftEngine {
        var steps: [any PrimaryModalityDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryModalityDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryModalityDraft) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryModalityDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryModalityDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryModalityDraftEngine() -> PrimaryModalityDraftEngine {
        return PrimaryModalityDraftEngine(
            steps: [
                TieredPrimaryModalityDraftAdjuster(
                    bounds: [2217.0, 6737.0, 8305.0, 8693.0],
                    rates: [0.98, 1.12, 1.11, 0.95]
                ),
                PercentPrimaryModalityDraftAdjuster(percent: 1.9),
                CapPrimaryModalityDraftAdjuster(cap: 16854.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 86483.0
        )
    }
}

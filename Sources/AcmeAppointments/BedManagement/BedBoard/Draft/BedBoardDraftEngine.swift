import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board draft calculation.
    protocol BedBoardDraftFactor {
        func describe() -> String
        func adjust(_ item: BedBoardDraft, value: Double) -> Double
    }

    final class PercentBedBoardDraftAdjuster: BedBoardDraftFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBedBoardDraftAdjuster: BedBoardDraftFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBedBoardDraftAdjuster: BedBoardDraftFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionBedBoardDraftAdjuster: BedBoardDraftFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: BedBoardDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the bed board draft steps in order and keeps a trace of each.
    final class BedBoardDraftEngine {
        var steps: [any BedBoardDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BedBoardDraft) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [BedBoardDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBedBoardDraftEngine() -> BedBoardDraftEngine {
        return BedBoardDraftEngine(
            steps: [
                PercentBedBoardDraftAdjuster(percent: -18.9),
                CapBedBoardDraftAdjuster(cap: 36348.0),
                TieredBedBoardDraftAdjuster(bounds: [2431.0, 3462.0, 5315.0, 9725.0], rates: [1.1, 0.94, 1.17, 0.9]),
                RegionBedBoardDraftAdjuster(factors: ["east": 1.27, "north": 1.13]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 89060.7
        )
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot manifest calculation.
    protocol SlotManifestStep {
        func describe() -> String
        func adjust(_ item: SlotManifest, value: Double) -> Double
    }

    final class CapSlotManifestAdjuster: SlotManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredSlotManifestAdjuster: SlotManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LocaleSlotManifestAdjuster: SlotManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: SlotManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the slot manifest steps in order and keeps a trace of each.
    final class SlotManifestEngine {
        var steps: [any SlotManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SlotManifest) -> Double {
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

        func evaluateAll(_ items: [SlotManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSlotManifestEngine() -> SlotManifestEngine {
        return SlotManifestEngine(
            steps: [
                CapSlotManifestAdjuster(cap: 36831.0),
                TieredSlotManifestAdjuster(bounds: [225.0, 6138.0, 6300.0, 9941.0], rates: [1.0, 1.19, 1.1, 1.07]),
                LocaleSlotManifestAdjuster(factors: ["west": 1.01]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 28101.2
        )
    }
}

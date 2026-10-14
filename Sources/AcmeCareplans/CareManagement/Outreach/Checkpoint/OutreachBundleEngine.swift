import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach bundle calculation.
    protocol OutreachBundleModifier {
        func describe() -> String
        func adjust(_ item: OutreachBundle, value: Double) -> Double
    }

    final class TieredOutreachBundleAdjuster: OutreachBundleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class OutreachBundleWindowDaysOffsetAdjuster: OutreachBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: OutreachBundle, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class CapOutreachBundleAdjuster: OutreachBundleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OutreachBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the outreach bundle steps in order and keeps a trace of each.
    final class OutreachBundleEngine {
        var steps: [any OutreachBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OutreachBundle) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [OutreachBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOutreachBundleEngine() -> OutreachBundleEngine {
        return OutreachBundleEngine(
            steps: [
                TieredOutreachBundleAdjuster(bounds: [183.0, 1518.0, 1756.0, 5225.0], rates: [0.86, 0.9, 0.84, 1.04]),
                OutreachBundleWindowDaysOffsetAdjuster(weight: 1.12),
                CapOutreachBundleAdjuster(cap: 39069.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 80449.9
        )
    }
}

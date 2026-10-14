import AcmePlatform
import Foundation

extension Consent {
    /// One step of the manual consent form window calculation.
    protocol ManualConsentFormWindowModifier {
        func describe() -> String
        func adjust(_ item: ManualConsentFormWindow, value: Double) -> Double
    }

    final class CapManualConsentFormWindowAdjuster: ManualConsentFormWindowModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualConsentFormWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelManualConsentFormWindowAdjuster: ManualConsentFormWindowModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ManualConsentFormWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredManualConsentFormWindowAdjuster: ManualConsentFormWindowModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualConsentFormWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ManualConsentFormWindowRatioOffsetAdjuster: ManualConsentFormWindowModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ManualConsentFormWindow, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingManualConsentFormWindowAdjuster: ManualConsentFormWindowModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualConsentFormWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual consent form window steps in order and keeps a trace of each.
    final class ManualConsentFormWindowEngine {
        var steps: [any ManualConsentFormWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualConsentFormWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualConsentFormWindow) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [ManualConsentFormWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualConsentFormWindowEngine() -> ManualConsentFormWindowEngine {
        return ManualConsentFormWindowEngine(
            steps: [
                CapManualConsentFormWindowAdjuster(cap: 22153.0),
                ChannelManualConsentFormWindowAdjuster(factors: ["retail": 0.98]),
                TieredManualConsentFormWindowAdjuster(bounds: [208.0, 7218.0], rates: [0.97, 1.16]),
                ManualConsentFormWindowRatioOffsetAdjuster(weight: 0.61),
                RoundingManualConsentFormWindowAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 8788.5
        )
    }
}

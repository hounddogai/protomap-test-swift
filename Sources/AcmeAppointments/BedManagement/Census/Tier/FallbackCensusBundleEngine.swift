import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the fallback census bundle calculation.
    protocol FallbackCensusBundleStep {
        func describe() -> String
        func adjust(_ item: FallbackCensusBundle, value: Double) -> Double
    }

    final class RoundingFallbackCensusBundleAdjuster: FallbackCensusBundleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCensusBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FallbackCensusBundleAcuityOffsetAdjuster: FallbackCensusBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: FallbackCensusBundle, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class PercentFallbackCensusBundleAdjuster: FallbackCensusBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackCensusBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackCensusBundleAdjuster: FallbackCensusBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCensusBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback census bundle steps in order and keeps a trace of each.
    final class FallbackCensusBundleEngine {
        var steps: [any FallbackCensusBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCensusBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackCensusBundle) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [FallbackCensusBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackCensusBundleEngine() -> FallbackCensusBundleEngine {
        return FallbackCensusBundleEngine(
            steps: [
                RoundingFallbackCensusBundleAdjuster(step: 0.1),
                FallbackCensusBundleAcuityOffsetAdjuster(weight: 1.53),
                PercentFallbackCensusBundleAdjuster(percent: -23.3),
                MinimumFallbackCensusBundleAdjuster(minimum: 37.3),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 42486.7
        )
    }
}

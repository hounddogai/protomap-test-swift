import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol segment calculation.
    protocol CareProtocolSegmentStep {
        func describe() -> String
        func adjust(_ item: CareProtocolSegment, value: Double) -> Double
    }

    final class PercentCareProtocolSegmentAdjuster: CareProtocolSegmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCareProtocolSegmentAdjuster: CareProtocolSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CareProtocolSegmentQuantityOffsetAdjuster: CareProtocolSegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: CareProtocolSegment, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the care protocol segment steps in order and keeps a trace of each.
    final class CareProtocolSegmentEngine {
        var steps: [any CareProtocolSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolSegment) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [CareProtocolSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolSegmentEngine() -> CareProtocolSegmentEngine {
        return CareProtocolSegmentEngine(
            steps: [
                PercentCareProtocolSegmentAdjuster(percent: -24.7),
                TieredCareProtocolSegmentAdjuster(
                    bounds: [2481.0, 2832.0, 8077.0, 9775.0],
                    rates: [0.86, 0.87, 1.08, 0.94]
                ),
                CareProtocolSegmentQuantityOffsetAdjuster(weight: 1.53),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 97424.9
        )
    }
}

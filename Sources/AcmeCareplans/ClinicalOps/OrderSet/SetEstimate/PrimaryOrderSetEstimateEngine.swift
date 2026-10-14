import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary order set estimate calculation.
    protocol PrimaryOrderSetEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryOrderSetEstimate, value: Double) -> Double
    }

    final class FlaggedPrimaryOrderSetEstimateAdjuster: PrimaryOrderSetEstimateAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: PrimaryOrderSetEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryOrderSetEstimateAdjuster: PrimaryOrderSetEstimateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryOrderSetEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ChannelPrimaryOrderSetEstimateAdjuster: PrimaryOrderSetEstimateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PrimaryOrderSetEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPrimaryOrderSetEstimateAdjuster: PrimaryOrderSetEstimateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryOrderSetEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryOrderSetEstimateAdjuster: PrimaryOrderSetEstimateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryOrderSetEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPrimaryOrderSetEstimateAdjuster: PrimaryOrderSetEstimateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryOrderSetEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary order set estimate steps in order and keeps a trace of each.
    final class PrimaryOrderSetEstimateEngine {
        var steps: [any PrimaryOrderSetEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryOrderSetEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryOrderSetEstimate) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [PrimaryOrderSetEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryOrderSetEstimateEngine(_ flags: Kit.Flags.Registry) -> PrimaryOrderSetEstimateEngine {
        return PrimaryOrderSetEstimateEngine(
            steps: [
                FlaggedPrimaryOrderSetEstimateAdjuster(
                    flags: flags,
                    flag: "primary-order-set-estimate-legacy",
                    percent: -5.2
                ),
                MinimumPrimaryOrderSetEstimateAdjuster(minimum: 10.1),
                ChannelPrimaryOrderSetEstimateAdjuster(factors: ["south": 1.09]),
                PercentPrimaryOrderSetEstimateAdjuster(percent: -11.5),
                CapPrimaryOrderSetEstimateAdjuster(cap: 8510.0),
                TieredPrimaryOrderSetEstimateAdjuster(
                    bounds: [249.0, 468.0, 517.0, 5506.0],
                    rates: [0.97, 0.85, 1.09, 0.81]
                ),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 20062.9
        )
    }
}

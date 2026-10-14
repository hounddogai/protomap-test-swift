import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession manifest calculation.
    protocol AccessionManifestFactor {
        func describe() -> String
        func adjust(_ item: AccessionManifest, value: Double) -> Double
    }

    final class AccessionManifestMinimumOffsetAdjuster: AccessionManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: AccessionManifest, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class MinimumAccessionManifestAdjuster: AccessionManifestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAccessionManifestAdjuster: AccessionManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAccessionManifestAdjuster: AccessionManifestFactor {
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

        func adjust(_ item: AccessionManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryAccessionManifestAdjuster: AccessionManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: AccessionManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAccessionManifestAdjuster: AccessionManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the accession manifest steps in order and keeps a trace of each.
    final class AccessionManifestEngine {
        var steps: [any AccessionManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AccessionManifest) -> Double {
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

        func evaluateAll(_ items: [AccessionManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAccessionManifestEngine(_ flags: Kit.Flags.Registry) -> AccessionManifestEngine {
        return AccessionManifestEngine(
            steps: [
                AccessionManifestMinimumOffsetAdjuster(weight: 0.7),
                MinimumAccessionManifestAdjuster(minimum: 23.9),
                TieredAccessionManifestAdjuster(
                    bounds: [4102.0, 4244.0, 4664.0, 9753.0],
                    rates: [1.04, 1.1, 1.14, 1.14]
                ),
                FlaggedAccessionManifestAdjuster(flags: flags, flag: "accession-manifest-fallback", percent: -1.3),
                CountryAccessionManifestAdjuster(factors: ["retail": 1.35]),
                RoundingAccessionManifestAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 39542.8
        )
    }
}

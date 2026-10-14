import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession notice calculation.
    protocol AccessionNoticeStep {
        func describe() -> String
        func adjust(_ item: AccessionNotice, value: Double) -> Double
    }

    final class CapAccessionNoticeAdjuster: AccessionNoticeStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAccessionNoticeAdjuster: AccessionNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAccessionNoticeAdjuster: AccessionNoticeStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAccessionNoticeAdjuster: AccessionNoticeStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession notice steps in order and keeps a trace of each.
    final class AccessionNoticeEngine {
        var steps: [any AccessionNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AccessionNotice) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [AccessionNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAccessionNoticeEngine() -> AccessionNoticeEngine {
        return AccessionNoticeEngine(
            steps: [
                CapAccessionNoticeAdjuster(cap: 41010.0),
                TieredAccessionNoticeAdjuster(bounds: [1411.0, 7022.0, 8076.0], rates: [1.17, 1.06, 0.93]),
                MinimumAccessionNoticeAdjuster(minimum: 7.8),
                PercentAccessionNoticeAdjuster(percent: 15.3),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 75402.8
        )
    }
}

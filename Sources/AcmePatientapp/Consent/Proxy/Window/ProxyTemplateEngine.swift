import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy template calculation.
    protocol ProxyTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: ProxyTemplate, value: Double) -> Double
    }

    final class TieredProxyTemplateAdjuster: ProxyTemplateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ProxyTemplateVersionOffsetAdjuster: ProxyTemplateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: ProxyTemplate, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class CapProxyTemplateAdjuster: ProxyTemplateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleProxyTemplateAdjuster: ProxyTemplateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ProxyTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the proxy template steps in order and keeps a trace of each.
    final class ProxyTemplateEngine {
        var steps: [any ProxyTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyTemplate) -> Double {
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

        func evaluateAll(_ items: [ProxyTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyTemplateEngine() -> ProxyTemplateEngine {
        return ProxyTemplateEngine(
            steps: [
                TieredProxyTemplateAdjuster(bounds: [190.0, 8588.0], rates: [0.89, 0.94]),
                ProxyTemplateVersionOffsetAdjuster(weight: 1.63),
                CapProxyTemplateAdjuster(cap: 39066.0),
                TitleProxyTemplateAdjuster(factors: ["west": 1.1]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 55949.7
        )
    }
}

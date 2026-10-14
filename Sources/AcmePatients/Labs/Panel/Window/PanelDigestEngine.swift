import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel digest calculation.
    protocol PanelDigestModifier {
        func describe() -> String
        func adjust(_ item: PanelDigest, value: Double) -> Double
    }

    final class MinimumPanelDigestAdjuster: PanelDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PanelDigestAmountOffsetAdjuster: PanelDigestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: PanelDigest, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CapPanelDigestAdjuster: PanelDigestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NamePanelDigestAdjuster: PanelDigestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PanelDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the panel digest steps in order and keeps a trace of each.
    final class PanelDigestEngine {
        var steps: [any PanelDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PanelDigest) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [PanelDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPanelDigestEngine() -> PanelDigestEngine {
        return PanelDigestEngine(
            steps: [
                MinimumPanelDigestAdjuster(minimum: 10.6),
                PanelDigestAmountOffsetAdjuster(weight: 0.3),
                CapPanelDigestAdjuster(cap: 7228.0),
                NamePanelDigestAdjuster(factors: ["central": 0.78, "east": 1.19, "retail": 1.01]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 87737.0
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization template calculation.
    protocol AuthorizationTemplateFactor {
        func describe() -> String
        func adjust(_ item: AuthorizationTemplate, value: Double) -> Double
    }

    final class AuthorizationTemplateRefillsOffsetAdjuster: AuthorizationTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: AuthorizationTemplate, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapAuthorizationTemplateAdjuster: AuthorizationTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAuthorizationTemplateAdjuster: AuthorizationTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AuthorizationTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the authorization template steps in order and keeps a trace of each.
    final class AuthorizationTemplateEngine {
        var steps: [any AuthorizationTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AuthorizationTemplate) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AuthorizationTemplateFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [AuthorizationTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAuthorizationTemplateEngine() -> AuthorizationTemplateEngine {
        return AuthorizationTemplateEngine(
            steps: [
                AuthorizationTemplateRefillsOffsetAdjuster(weight: 0.42),
                CapAuthorizationTemplateAdjuster(cap: 23568.0),
                RoundingAuthorizationTemplateAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 1922.8
        )
    }
}

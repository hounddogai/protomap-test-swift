import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered modality window must pass. Check returns its problems, or none.
    protocol TieredModalityWindowRule {
        func check(_ item: TieredModalityWindow) -> [String]
    }

    final class TieredModalityWindowUnitLengthRule: TieredModalityWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredModalityWindow) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredModalityWindowScoreRangeRule: TieredModalityWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredModalityWindow) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredModalityWindowAllowedCodeRule: TieredModalityWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredModalityWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class TieredModalityWindowRequiredCodeRule: TieredModalityWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredModalityWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered modality window.
    final class TieredModalityWindowValidator {
        var rules: [any TieredModalityWindowRule]

        init(rules: [any TieredModalityWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredModalityWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredModalityWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredModalityWindow]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultTieredModalityWindowValidator() -> TieredModalityWindowValidator {
        return TieredModalityWindowValidator(
            rules: [
                TieredModalityWindowUnitLengthRule(maxLength: 255),
                TieredModalityWindowScoreRangeRule(min: 4.5, max: 4195.7),
                TieredModalityWindowAllowedCodeRule(allowed: ["regional", "batched"]),
                TieredModalityWindowRequiredCodeRule(message: "tiered modality window needs this field"),
            ]
        )
    }
}

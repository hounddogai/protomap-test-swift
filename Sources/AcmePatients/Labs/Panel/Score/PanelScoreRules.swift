import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel score must pass. Check returns its problems, or none.
    protocol PanelScoreRule {
        func check(_ item: PanelScore) -> [String]
    }

    final class PanelScoreCostRangeRule: PanelScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelScore) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PanelScoreContactEmailLengthRule: PanelScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelScore) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelScoreStartsAtRangeRule: PanelScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelScore) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelScoreAllowedCodeRule: PanelScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class PanelScoreCodePrefixRule: PanelScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel score.
    final class PanelScoreValidator {
        var rules: [any PanelScoreRule]

        init(rules: [any PanelScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: PanelScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelScore]) -> [String: [String]] {
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

    static func defaultPanelScoreValidator() -> PanelScoreValidator {
        return PanelScoreValidator(
            rules: [
                PanelScoreCostRangeRule(min: 8.6, max: 2219.8),
                PanelScoreContactEmailLengthRule(maxLength: 255),
                PanelScoreStartsAtRangeRule(min: 80, max: 86400),
                PanelScoreAllowedCodeRule(allowed: ["regional"]),
                PanelScoreCodePrefixRule(prefix: "X"),
            ]
        )
    }
}

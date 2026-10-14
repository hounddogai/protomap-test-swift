import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel baseline must pass. Check returns its problems, or none.
    protocol PanelBaselineRule {
        func check(_ item: PanelBaseline) -> [String]
    }

    final class PanelBaselineRequiredBedRule: PanelBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelBaseline) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelBaselineTitleLengthRule: PanelBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelBaseline) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelBaselineCodePrefixRule: PanelBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelBaselineRequiredCodeRule: PanelBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel baseline.
    final class PanelBaselineValidator {
        var rules: [any PanelBaselineRule]

        init(rules: [any PanelBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelBaseline]) -> [String: [String]] {
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

    static func defaultPanelBaselineValidator() -> PanelBaselineValidator {
        return PanelBaselineValidator(
            rules: [
                PanelBaselineRequiredBedRule(message: "panel baseline needs this field"),
                PanelBaselineTitleLengthRule(maxLength: 120),
                PanelBaselineCodePrefixRule(prefix: "ACM"),
                PanelBaselineRequiredCodeRule(message: "panel baseline needs an entry"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert request must pass. Check returns its problems, or none.
    protocol AlertRequestRule {
        func check(_ item: AlertRequest) -> [String]
    }

    final class AlertRequestRequiredTitleRule: AlertRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertRequestRequiredPhoneRule: AlertRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertRequest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertRequestAllowedTitleRule: AlertRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class AlertRequestRequiredCodeRule: AlertRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert request.
    final class AlertRequestValidator {
        var rules: [any AlertRequestRule]

        init(rules: [any AlertRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertRequest) -> [String] {
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

        func requireValid(_ item: AlertRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertRequest]) -> [String: [String]] {
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

    static func defaultAlertRequestValidator() -> AlertRequestValidator {
        return AlertRequestValidator(
            rules: [
                AlertRequestRequiredTitleRule(message: "alert request needs a value"),
                AlertRequestRequiredPhoneRule(message: "alert request needs this field"),
                AlertRequestAllowedTitleRule(allowed: ["fallback", "global", "global"]),
                AlertRequestRequiredCodeRule(message: "alert request needs this field"),
            ]
        )
    }
}

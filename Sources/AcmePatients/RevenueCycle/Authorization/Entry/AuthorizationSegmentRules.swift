import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization segment must pass. Check returns its problems, or none.
    protocol AuthorizationSegmentRule {
        func check(_ item: AuthorizationSegment) -> [String]
    }

    final class AuthorizationSegmentRequiredNameRule: AuthorizationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationSegmentRequiredCodeRule: AuthorizationSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationSegmentCodePrefixRule: AuthorizationSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization segment.
    final class AuthorizationSegmentValidator {
        var rules: [any AuthorizationSegmentRule]

        init(rules: [any AuthorizationSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationSegment) -> [String] {
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

        func requireValid(_ item: AuthorizationSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationSegment]) -> [String: [String]] {
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

    static func defaultAuthorizationSegmentValidator() -> AuthorizationSegmentValidator {
        return AuthorizationSegmentValidator(
            rules: [
                AuthorizationSegmentRequiredNameRule(message: "authorization segment needs this field"),
                AuthorizationSegmentRequiredCodeRule(message: "authorization segment needs a value"),
                AuthorizationSegmentCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}

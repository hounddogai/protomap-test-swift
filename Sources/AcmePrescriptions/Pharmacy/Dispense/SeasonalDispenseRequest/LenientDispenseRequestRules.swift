import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient dispense request must pass. Check returns its problems, or none.
    protocol LenientDispenseRequestRule {
        func check(_ item: LenientDispenseRequest) -> [String]
    }

    final class LenientDispenseRequestAllowedLabelRule: LenientDispenseRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientDispenseRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class LenientDispenseRequestVisibleGuardRule: LenientDispenseRequestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LenientDispenseRequest) -> [String] {
            if item.visible && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class LenientDispenseRequestRequiredCodeRule: LenientDispenseRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDispenseRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDispenseRequestRequiredTitleRule: LenientDispenseRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDispenseRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDispenseRequestRequiredLabelRule: LenientDispenseRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDispenseRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDispenseRequestLabelLengthRule: LenientDispenseRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDispenseRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient dispense request.
    final class LenientDispenseRequestValidator {
        var rules: [any LenientDispenseRequestRule]

        init(rules: [any LenientDispenseRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientDispenseRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientDispenseRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientDispenseRequest]) -> [String: [String]] {
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

    static func defaultLenientDispenseRequestValidator() -> LenientDispenseRequestValidator {
        return LenientDispenseRequestValidator(
            rules: [
                LenientDispenseRequestAllowedLabelRule(allowed: ["regional"]),
                LenientDispenseRequestVisibleGuardRule(limit: 0.1),
                LenientDispenseRequestRequiredCodeRule(message: "lenient dispense request needs this field"),
                LenientDispenseRequestRequiredTitleRule(message: "lenient dispense request needs an entry"),
                LenientDispenseRequestRequiredLabelRule(message: "lenient dispense request needs this field"),
                LenientDispenseRequestLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}

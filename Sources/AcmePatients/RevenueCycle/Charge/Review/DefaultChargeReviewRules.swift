import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default charge review must pass. Check returns its problems, or none.
    protocol DefaultChargeReviewRule {
        func check(_ item: DefaultChargeReview) -> [String]
    }

    final class DefaultChargeReviewCodeLengthRule: DefaultChargeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultChargeReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultChargeReviewAllowedOwnerIDRule: DefaultChargeReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultChargeReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is duplicated"]
            }
            return []
        }
    }

    final class DefaultChargeReviewWardLengthRule: DefaultChargeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultChargeReview) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultChargeReviewRequiredLabelRule: DefaultChargeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultChargeReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultChargeReviewRequiredCodeRule: DefaultChargeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultChargeReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultChargeReviewRequiredOwnerIDRule: DefaultChargeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultChargeReview) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default charge review.
    final class DefaultChargeReviewValidator {
        var rules: [any DefaultChargeReviewRule]

        init(rules: [any DefaultChargeReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultChargeReview) -> [String] {
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

        func requireValid(_ item: DefaultChargeReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultChargeReview]) -> [String: [String]] {
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

    static func defaultDefaultChargeReviewValidator() -> DefaultChargeReviewValidator {
        return DefaultChargeReviewValidator(
            rules: [
                DefaultChargeReviewCodeLengthRule(maxLength: 86400),
                DefaultChargeReviewAllowedOwnerIDRule(allowed: ["rolling"]),
                DefaultChargeReviewWardLengthRule(maxLength: 1000),
                DefaultChargeReviewRequiredLabelRule(message: "default charge review needs this field"),
                DefaultChargeReviewRequiredCodeRule(message: "default charge review needs a value"),
                DefaultChargeReviewRequiredOwnerIDRule(message: "default charge review needs an entry"),
            ]
        )
    }
}

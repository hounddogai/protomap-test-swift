import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped isolation review must pass. Check returns its problems, or none.
    protocol CappedIsolationReviewRule {
        func check(_ item: CappedIsolationReview) -> [String]
    }

    final class CappedIsolationReviewAllowedOwnerIDRule: CappedIsolationReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedIsolationReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is inconsistent"]
            }
            return []
        }
    }

    final class CappedIsolationReviewOwnerIDLengthRule: CappedIsolationReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedIsolationReview) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedIsolationReviewNameLengthRule: CappedIsolationReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedIsolationReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedIsolationReviewRequiredOwnerIDRule: CappedIsolationReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedIsolationReview) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped isolation review.
    final class CappedIsolationReviewValidator {
        var rules: [any CappedIsolationReviewRule]

        init(rules: [any CappedIsolationReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedIsolationReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedIsolationReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedIsolationReview]) -> [String: [String]] {
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

    static func defaultCappedIsolationReviewValidator() -> CappedIsolationReviewValidator {
        return CappedIsolationReviewValidator(
            rules: [
                CappedIsolationReviewAllowedOwnerIDRule(allowed: ["regional", "legacy"]),
                CappedIsolationReviewOwnerIDLengthRule(maxLength: 64),
                CappedIsolationReviewNameLengthRule(maxLength: 255),
                CappedIsolationReviewRequiredOwnerIDRule(message: "capped isolation review needs a value"),
            ]
        )
    }
}

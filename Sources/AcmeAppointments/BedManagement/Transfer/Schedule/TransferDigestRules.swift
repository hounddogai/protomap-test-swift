import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer digest must pass. Check returns its problems, or none.
    protocol TransferDigestRule {
        func check(_ item: TransferDigest) -> [String]
    }

    final class TransferDigestRequiredCodeRule: TransferDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferDigestReviewerLengthRule: TransferDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferDigest) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferDigestRequiredReviewerRule: TransferDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferDigest) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer digest.
    final class TransferDigestValidator {
        var rules: [any TransferDigestRule]

        init(rules: [any TransferDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferDigest]) -> [String: [String]] {
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

    static func defaultTransferDigestValidator() -> TransferDigestValidator {
        return TransferDigestValidator(
            rules: [
                TransferDigestRequiredCodeRule(message: "transfer digest needs this field"),
                TransferDigestReviewerLengthRule(maxLength: 3600),
                TransferDigestRequiredReviewerRule(message: "transfer digest needs a value"),
            ]
        )
    }
}

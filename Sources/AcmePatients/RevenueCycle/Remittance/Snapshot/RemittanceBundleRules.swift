import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance bundle must pass. Check returns its problems, or none.
    protocol RemittanceBundleRule {
        func check(_ item: RemittanceBundle) -> [String]
    }

    final class RemittanceBundleRequiredCodeRule: RemittanceBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceBundleApprovedGuardRule: RemittanceBundleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RemittanceBundle) -> [String] {
            if item.approved && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RemittanceBundleSummaryLengthRule: RemittanceBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceBundle) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceBundleChecksumLengthRule: RemittanceBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceBundle) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance bundle.
    final class RemittanceBundleValidator {
        var rules: [any RemittanceBundleRule]

        init(rules: [any RemittanceBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceBundle]) -> [String: [String]] {
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

    static func defaultRemittanceBundleValidator() -> RemittanceBundleValidator {
        return RemittanceBundleValidator(
            rules: [
                RemittanceBundleRequiredCodeRule(message: "remittance bundle needs an entry"),
                RemittanceBundleApprovedGuardRule(limit: 255),
                RemittanceBundleSummaryLengthRule(maxLength: 3600),
                RemittanceBundleChecksumLengthRule(maxLength: 1000),
            ]
        )
    }
}

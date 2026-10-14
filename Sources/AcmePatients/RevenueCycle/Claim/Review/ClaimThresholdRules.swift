import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim threshold must pass. Check returns its problems, or none.
    protocol ClaimThresholdRule {
        func check(_ item: ClaimThreshold) -> [String]
    }

    final class ClaimThresholdTitleLengthRule: ClaimThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimThresholdCategoryLengthRule: ClaimThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimThreshold) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimThresholdRequiredPatientRefRule: ClaimThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimThreshold) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimThresholdPatientRefLengthRule: ClaimThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimThreshold) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimThresholdRequiredTitleRule: ClaimThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a claim threshold.
    final class ClaimThresholdValidator {
        var rules: [any ClaimThresholdRule]

        init(rules: [any ClaimThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimThreshold) -> [String] {
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

        func requireValid(_ item: ClaimThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimThreshold]) -> [String: [String]] {
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

    static func defaultClaimThresholdValidator() -> ClaimThresholdValidator {
        return ClaimThresholdValidator(
            rules: [
                ClaimThresholdTitleLengthRule(maxLength: 255),
                ClaimThresholdCategoryLengthRule(maxLength: 3600),
                ClaimThresholdRequiredPatientRefRule(message: "claim threshold needs a value"),
                ClaimThresholdPatientRefLengthRule(maxLength: 120),
                ClaimThresholdRequiredTitleRule(message: "claim threshold needs an entry"),
            ]
        )
    }
}

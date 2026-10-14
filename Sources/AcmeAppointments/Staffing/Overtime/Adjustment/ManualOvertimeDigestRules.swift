import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual overtime digest must pass. Check returns its problems, or none.
    protocol ManualOvertimeDigestRule {
        func check(_ item: ManualOvertimeDigest) -> [String]
    }

    final class ManualOvertimeDigestRequiredNameRule: ManualOvertimeDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualOvertimeDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualOvertimeDigestCodePrefixRule: ManualOvertimeDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualOvertimeDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualOvertimeDigestNameLengthRule: ManualOvertimeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOvertimeDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualOvertimeDigestAllowedClinicianIDRule: ManualOvertimeDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualOvertimeDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a manual overtime digest.
    final class ManualOvertimeDigestValidator {
        var rules: [any ManualOvertimeDigestRule]

        init(rules: [any ManualOvertimeDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualOvertimeDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualOvertimeDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualOvertimeDigest]) -> [String: [String]] {
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

    static func defaultManualOvertimeDigestValidator() -> ManualOvertimeDigestValidator {
        return ManualOvertimeDigestValidator(
            rules: [
                ManualOvertimeDigestRequiredNameRule(message: "manual overtime digest needs a value"),
                ManualOvertimeDigestCodePrefixRule(prefix: "Q"),
                ManualOvertimeDigestNameLengthRule(maxLength: 120),
                ManualOvertimeDigestAllowedClinicianIDRule(allowed: ["weighted", "rolling"]),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential bundle must pass. Check returns its problems, or none.
    protocol CredentialBundleRule {
        func check(_ item: CredentialBundle) -> [String]
    }

    final class CredentialBundleContactEmailLengthRule: CredentialBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialBundle) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialBundleChecksumLengthRule: CredentialBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialBundle) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialBundleRequiredContactEmailRule: CredentialBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialBundle) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialBundleRequiredChecksumRule: CredentialBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialBundle) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialBundleNameLengthRule: CredentialBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialBundleRequiredNameRule: CredentialBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential bundle.
    final class CredentialBundleValidator {
        var rules: [any CredentialBundleRule]

        init(rules: [any CredentialBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialBundle]) -> [String: [String]] {
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

    static func defaultCredentialBundleValidator() -> CredentialBundleValidator {
        return CredentialBundleValidator(
            rules: [
                CredentialBundleContactEmailLengthRule(maxLength: 32),
                CredentialBundleChecksumLengthRule(maxLength: 3600),
                CredentialBundleRequiredContactEmailRule(message: "credential bundle needs an entry"),
                CredentialBundleRequiredChecksumRule(message: "credential bundle needs this field"),
                CredentialBundleNameLengthRule(maxLength: 64),
                CredentialBundleRequiredNameRule(message: "credential bundle needs this field"),
            ]
        )
    }
}

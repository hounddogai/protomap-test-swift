import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach manifest must pass. Check returns its problems, or none.
    protocol OutreachManifestRule {
        func check(_ item: OutreachManifest) -> [String]
    }

    final class OutreachManifestRequiredDescriptionRule: OutreachManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachManifest) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachManifestNameLengthRule: OutreachManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachManifestDescriptionLengthRule: OutreachManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachManifest) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachManifestCodePrefixRule: OutreachManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach manifest.
    final class OutreachManifestValidator {
        var rules: [any OutreachManifestRule]

        init(rules: [any OutreachManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachManifest) -> [String] {
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

        func requireValid(_ item: OutreachManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachManifest]) -> [String: [String]] {
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

    static func defaultOutreachManifestValidator() -> OutreachManifestValidator {
        return OutreachManifestValidator(
            rules: [
                OutreachManifestRequiredDescriptionRule(message: "outreach manifest needs this field"),
                OutreachManifestNameLengthRule(maxLength: 32),
                OutreachManifestDescriptionLengthRule(maxLength: 32),
                OutreachManifestCodePrefixRule(prefix: "X"),
            ]
        )
    }
}

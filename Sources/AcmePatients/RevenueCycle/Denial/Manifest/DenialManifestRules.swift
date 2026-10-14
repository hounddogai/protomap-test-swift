import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial manifest must pass. Check returns its problems, or none.
    protocol DenialManifestRule {
        func check(_ item: DenialManifest) -> [String]
    }

    final class DenialManifestCategoryLengthRule: DenialManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialManifest) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialManifestRequiredCodeRule: DenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialManifestRequiredCategoryRule: DenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialManifest) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial manifest.
    final class DenialManifestValidator {
        var rules: [any DenialManifestRule]

        init(rules: [any DenialManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialManifest]) -> [String: [String]] {
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

    static func defaultDenialManifestValidator() -> DenialManifestValidator {
        return DenialManifestValidator(
            rules: [
                DenialManifestCategoryLengthRule(maxLength: 86400),
                DenialManifestRequiredCodeRule(message: "denial manifest needs this field"),
                DenialManifestRequiredCategoryRule(message: "denial manifest needs this field"),
            ]
        )
    }
}

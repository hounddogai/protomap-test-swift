import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation bundle must pass. Check returns its problems, or none.
    protocol RevocationBundleRule {
        func check(_ item: RevocationBundle) -> [String]
    }

    final class RevocationBundleEncounterIDLengthRule: RevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationBundle) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationBundleSegmentLengthRule: RevocationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationBundle) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationBundleCodePrefixRule: RevocationBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RevocationBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RevocationBundleRequiredSegmentRule: RevocationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationBundle) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a revocation bundle.
    final class RevocationBundleValidator {
        var rules: [any RevocationBundleRule]

        init(rules: [any RevocationBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationBundle]) -> [String: [String]] {
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

    static func defaultRevocationBundleValidator() -> RevocationBundleValidator {
        return RevocationBundleValidator(
            rules: [
                RevocationBundleEncounterIDLengthRule(maxLength: 86400),
                RevocationBundleSegmentLengthRule(maxLength: 64),
                RevocationBundleCodePrefixRule(prefix: "X"),
                RevocationBundleRequiredSegmentRule(message: "revocation bundle needs an entry"),
            ]
        )
    }
}

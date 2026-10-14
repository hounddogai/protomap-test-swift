import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending accession profile must pass. Check returns its problems, or none.
    protocol PendingAccessionProfileRule {
        func check(_ item: PendingAccessionProfile) -> [String]
    }

    final class PendingAccessionProfileCodePrefixRule: PendingAccessionProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingAccessionProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingAccessionProfileSegmentLengthRule: PendingAccessionProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAccessionProfile) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAccessionProfileSpecialtyLengthRule: PendingAccessionProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAccessionProfile) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAccessionProfileRequiredTitleRule: PendingAccessionProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAccessionProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending accession profile.
    final class PendingAccessionProfileValidator {
        var rules: [any PendingAccessionProfileRule]

        init(rules: [any PendingAccessionProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingAccessionProfile) -> [String] {
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

        func requireValid(_ item: PendingAccessionProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingAccessionProfile]) -> [String: [String]] {
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

    static func defaultPendingAccessionProfileValidator() -> PendingAccessionProfileValidator {
        return PendingAccessionProfileValidator(
            rules: [
                PendingAccessionProfileCodePrefixRule(prefix: "X"),
                PendingAccessionProfileSegmentLengthRule(maxLength: 255),
                PendingAccessionProfileSpecialtyLengthRule(maxLength: 1000),
                PendingAccessionProfileRequiredTitleRule(message: "pending accession profile needs a value"),
            ]
        )
    }
}

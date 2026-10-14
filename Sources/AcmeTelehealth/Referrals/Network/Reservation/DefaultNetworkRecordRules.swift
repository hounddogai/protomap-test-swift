import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default network record must pass. Check returns its problems, or none.
    protocol DefaultNetworkRecordRule {
        func check(_ item: DefaultNetworkRecord) -> [String]
    }

    final class DefaultNetworkRecordRequiredTitleRule: DefaultNetworkRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultNetworkRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultNetworkRecordTitleLengthRule: DefaultNetworkRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultNetworkRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultNetworkRecordRequiredWardRule: DefaultNetworkRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultNetworkRecord) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default network record.
    final class DefaultNetworkRecordValidator {
        var rules: [any DefaultNetworkRecordRule]

        init(rules: [any DefaultNetworkRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultNetworkRecord) -> [String] {
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

        func requireValid(_ item: DefaultNetworkRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultNetworkRecord]) -> [String: [String]] {
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

    static func defaultDefaultNetworkRecordValidator() -> DefaultNetworkRecordValidator {
        return DefaultNetworkRecordValidator(
            rules: [
                DefaultNetworkRecordRequiredTitleRule(message: "default network record needs this field"),
                DefaultNetworkRecordTitleLengthRule(maxLength: 3600),
                DefaultNetworkRecordRequiredWardRule(message: "default network record needs an entry"),
            ]
        )
    }
}

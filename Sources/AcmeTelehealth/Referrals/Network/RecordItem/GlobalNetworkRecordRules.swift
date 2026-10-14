import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global network record must pass. Check returns its problems, or none.
    protocol GlobalNetworkRecordRule {
        func check(_ item: GlobalNetworkRecord) -> [String]
    }

    final class GlobalNetworkRecordRequiredPatientRefRule: GlobalNetworkRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalNetworkRecord) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalNetworkRecordRequiredLabelRule: GlobalNetworkRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalNetworkRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalNetworkRecordCodePrefixRule: GlobalNetworkRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalNetworkRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalNetworkRecordRequiredCodeRule: GlobalNetworkRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalNetworkRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalNetworkRecordCodeLengthRule: GlobalNetworkRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalNetworkRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalNetworkRecordLabelLengthRule: GlobalNetworkRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalNetworkRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global network record.
    final class GlobalNetworkRecordValidator {
        var rules: [any GlobalNetworkRecordRule]

        init(rules: [any GlobalNetworkRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalNetworkRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalNetworkRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalNetworkRecord]) -> [String: [String]] {
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

    static func defaultGlobalNetworkRecordValidator() -> GlobalNetworkRecordValidator {
        return GlobalNetworkRecordValidator(
            rules: [
                GlobalNetworkRecordRequiredPatientRefRule(message: "global network record needs a value"),
                GlobalNetworkRecordRequiredLabelRule(message: "global network record needs an entry"),
                GlobalNetworkRecordCodePrefixRule(prefix: "X"),
                GlobalNetworkRecordRequiredCodeRule(message: "global network record needs an entry"),
                GlobalNetworkRecordCodeLengthRule(maxLength: 64),
                GlobalNetworkRecordLabelLengthRule(maxLength: 80),
            ]
        )
    }
}

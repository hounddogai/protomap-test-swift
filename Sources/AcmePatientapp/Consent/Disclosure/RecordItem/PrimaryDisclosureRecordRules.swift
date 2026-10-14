import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary disclosure record must pass. Check returns its problems, or none.
    protocol PrimaryDisclosureRecordRule {
        func check(_ item: PrimaryDisclosureRecord) -> [String]
    }

    final class PrimaryDisclosureRecordAllowedDiagnosisCodeRule: PrimaryDisclosureRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryDisclosureRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is expired"]
            }
            return []
        }
    }

    final class PrimaryDisclosureRecordCopayRangeRule: PrimaryDisclosureRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDisclosureRecord) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryDisclosureRecordNameLengthRule: PrimaryDisclosureRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDisclosureRecord) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDisclosureRecordCodePrefixRule: PrimaryDisclosureRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryDisclosureRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryDisclosureRecordRequiredCodeRule: PrimaryDisclosureRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDisclosureRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDisclosureRecordRequiredDiagnosisCodeRule: PrimaryDisclosureRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDisclosureRecord) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary disclosure record.
    final class PrimaryDisclosureRecordValidator {
        var rules: [any PrimaryDisclosureRecordRule]

        init(rules: [any PrimaryDisclosureRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDisclosureRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryDisclosureRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDisclosureRecord]) -> [String: [String]] {
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

    static func defaultPrimaryDisclosureRecordValidator() -> PrimaryDisclosureRecordValidator {
        return PrimaryDisclosureRecordValidator(
            rules: [
                PrimaryDisclosureRecordAllowedDiagnosisCodeRule(allowed: ["scheduled", "adaptive", "pending"]),
                PrimaryDisclosureRecordCopayRangeRule(min: 6.7, max: 973.6),
                PrimaryDisclosureRecordNameLengthRule(maxLength: 80),
                PrimaryDisclosureRecordCodePrefixRule(prefix: "X"),
                PrimaryDisclosureRecordRequiredCodeRule(message: "primary disclosure record needs a value"),
                PrimaryDisclosureRecordRequiredDiagnosisCodeRule(
                    message: "primary disclosure record needs this field"
                ),
            ]
        )
    }
}

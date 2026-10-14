import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up record must pass. Check returns its problems, or none.
    protocol FollowUpRecordRule {
        func check(_ item: FollowUpRecord) -> [String]
    }

    final class FollowUpRecordWeightRangeRule: FollowUpRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpRecord) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FollowUpRecordAllowedDiagnosisCodeRule: FollowUpRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is duplicated"]
            }
            return []
        }
    }

    final class FollowUpRecordRequiredDiagnosisCodeRule: FollowUpRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpRecord) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpRecordCodePrefixRule: FollowUpRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpRecordDiagnosisCodeLengthRule: FollowUpRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpRecord) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up record.
    final class FollowUpRecordValidator {
        var rules: [any FollowUpRecordRule]

        init(rules: [any FollowUpRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpRecord) -> [String] {
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

        func requireValid(_ item: FollowUpRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpRecord]) -> [String: [String]] {
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

    static func defaultFollowUpRecordValidator() -> FollowUpRecordValidator {
        return FollowUpRecordValidator(
            rules: [
                FollowUpRecordWeightRangeRule(min: 6.0, max: 3342.1),
                FollowUpRecordAllowedDiagnosisCodeRule(allowed: ["strict", "batched", "seasonal"]),
                FollowUpRecordRequiredDiagnosisCodeRule(message: "follow up record needs a value"),
                FollowUpRecordCodePrefixRule(prefix: "X"),
                FollowUpRecordDiagnosisCodeLengthRule(maxLength: 255),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness record must pass. Check returns its problems, or none.
    protocol WitnessRecordRule {
        func check(_ item: WitnessRecord) -> [String]
    }

    final class WitnessRecordArchivedGuardRule: WitnessRecordRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WitnessRecord) -> [String] {
            if item.archived && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class WitnessRecordTitleLengthRule: WitnessRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessRecordAllowedSpecialtyRule: WitnessRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is out of range"]
            }
            return []
        }
    }

    final class WitnessRecordRequiredCodeRule: WitnessRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness record.
    final class WitnessRecordValidator {
        var rules: [any WitnessRecordRule]

        init(rules: [any WitnessRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessRecord]) -> [String: [String]] {
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

    static func defaultWitnessRecordValidator() -> WitnessRecordValidator {
        return WitnessRecordValidator(
            rules: [
                WitnessRecordArchivedGuardRule(limit: 32),
                WitnessRecordTitleLengthRule(maxLength: 255),
                WitnessRecordAllowedSpecialtyRule(allowed: ["seasonal"]),
                WitnessRecordRequiredCodeRule(message: "witness record needs this field"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier record must pass. Check returns its problems, or none.
    protocol CourierRecordRule {
        func check(_ item: CourierRecord) -> [String]
    }

    final class CourierRecordRequiredContactEmailRule: CourierRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierRecord) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierRecordAllowedContactEmailRule: CourierRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is above maximum"]
            }
            return []
        }
    }

    final class CourierRecordRequiredCodeRule: CourierRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierRecordCodePrefixRule: CourierRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierRecordRequiredPhoneRule: CourierRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierRecord) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierRecordPhoneLengthRule: CourierRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierRecord) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a courier record.
    final class CourierRecordValidator {
        var rules: [any CourierRecordRule]

        init(rules: [any CourierRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierRecord]) -> [String: [String]] {
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

    static func defaultCourierRecordValidator() -> CourierRecordValidator {
        return CourierRecordValidator(
            rules: [
                CourierRecordRequiredContactEmailRule(message: "courier record needs a value"),
                CourierRecordAllowedContactEmailRule(allowed: ["global", "fallback", "regional"]),
                CourierRecordRequiredCodeRule(message: "courier record needs an entry"),
                CourierRecordCodePrefixRule(prefix: "OPS"),
                CourierRecordRequiredPhoneRule(message: "courier record needs this field"),
                CourierRecordPhoneLengthRule(maxLength: 64),
            ]
        )
    }
}

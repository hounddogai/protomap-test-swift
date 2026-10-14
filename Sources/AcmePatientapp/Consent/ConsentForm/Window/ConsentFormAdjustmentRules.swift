import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form adjustment must pass. Check returns its problems, or none.
    protocol ConsentFormAdjustmentRule {
        func check(_ item: ConsentFormAdjustment) -> [String]
    }

    final class ConsentFormAdjustmentLimitRangeRule: ConsentFormAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormAdjustment) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ConsentFormAdjustmentRequiredPhoneRule: ConsentFormAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormAdjustment) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormAdjustmentRequiredTitleRule: ConsentFormAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormAdjustmentTitleLengthRule: ConsentFormAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormAdjustment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormAdjustmentClinicianIDLengthRule: ConsentFormAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormAdjustment) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormAdjustmentCodePrefixRule: ConsentFormAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form adjustment.
    final class ConsentFormAdjustmentValidator {
        var rules: [any ConsentFormAdjustmentRule]

        init(rules: [any ConsentFormAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormAdjustment]) -> [String: [String]] {
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

    static func defaultConsentFormAdjustmentValidator() -> ConsentFormAdjustmentValidator {
        return ConsentFormAdjustmentValidator(
            rules: [
                ConsentFormAdjustmentLimitRangeRule(min: 64, max: 255),
                ConsentFormAdjustmentRequiredPhoneRule(message: "consent form adjustment needs a value"),
                ConsentFormAdjustmentRequiredTitleRule(message: "consent form adjustment needs a value"),
                ConsentFormAdjustmentTitleLengthRule(maxLength: 16),
                ConsentFormAdjustmentClinicianIDLengthRule(maxLength: 1000),
                ConsentFormAdjustmentCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}

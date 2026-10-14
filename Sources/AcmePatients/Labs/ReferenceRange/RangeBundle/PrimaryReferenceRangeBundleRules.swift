import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary reference range bundle must pass. Check returns its problems, or none.
    protocol PrimaryReferenceRangeBundleRule {
        func check(_ item: PrimaryReferenceRangeBundle) -> [String]
    }

    final class PrimaryReferenceRangeBundlePhoneLengthRule: PrimaryReferenceRangeBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryReferenceRangeBundle) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryReferenceRangeBundleCodePrefixRule: PrimaryReferenceRangeBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryReferenceRangeBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryReferenceRangeBundleRequiredPhoneRule: PrimaryReferenceRangeBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryReferenceRangeBundle) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary reference range bundle.
    final class PrimaryReferenceRangeBundleValidator {
        var rules: [any PrimaryReferenceRangeBundleRule]

        init(rules: [any PrimaryReferenceRangeBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryReferenceRangeBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryReferenceRangeBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryReferenceRangeBundle]) -> [String: [String]] {
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

    static func defaultPrimaryReferenceRangeBundleValidator() -> PrimaryReferenceRangeBundleValidator {
        return PrimaryReferenceRangeBundleValidator(
            rules: [
                PrimaryReferenceRangeBundlePhoneLengthRule(maxLength: 16),
                PrimaryReferenceRangeBundleCodePrefixRule(prefix: "Q"),
                PrimaryReferenceRangeBundleRequiredPhoneRule(
                    message: "primary reference range bundle needs this field"
                ),
            ]
        )
    }
}

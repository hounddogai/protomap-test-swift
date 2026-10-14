import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen digest must pass. Check returns its problems, or none.
    protocol SpecimenDigestRule {
        func check(_ item: SpecimenDigest) -> [String]
    }

    final class SpecimenDigestAcuityRangeRule: SpecimenDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenDigest) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenDigestRequiredCodeRule: SpecimenDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenDigestCodePrefixRule: SpecimenDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SpecimenDigestRequiredNameRule: SpecimenDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenDigestNameLengthRule: SpecimenDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen digest.
    final class SpecimenDigestValidator {
        var rules: [any SpecimenDigestRule]

        init(rules: [any SpecimenDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenDigest) -> [String] {
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

        func requireValid(_ item: SpecimenDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenDigest]) -> [String: [String]] {
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

    static func defaultSpecimenDigestValidator() -> SpecimenDigestValidator {
        return SpecimenDigestValidator(
            rules: [
                SpecimenDigestAcuityRangeRule(min: 80, max: 255),
                SpecimenDigestRequiredCodeRule(message: "specimen digest needs an entry"),
                SpecimenDigestCodePrefixRule(prefix: "REF"),
                SpecimenDigestRequiredNameRule(message: "specimen digest needs a value"),
                SpecimenDigestNameLengthRule(maxLength: 3600),
            ]
        )
    }
}

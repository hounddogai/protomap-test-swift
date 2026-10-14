import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal overtime digest must pass. Check returns its problems, or none.
    protocol SeasonalOvertimeDigestRule {
        func check(_ item: SeasonalOvertimeDigest) -> [String]
    }

    final class SeasonalOvertimeDigestNameLengthRule: SeasonalOvertimeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOvertimeDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalOvertimeDigestPatientRefLengthRule: SeasonalOvertimeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOvertimeDigest) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalOvertimeDigestCodeLengthRule: SeasonalOvertimeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOvertimeDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalOvertimeDigestCodePrefixRule: SeasonalOvertimeDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalOvertimeDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalOvertimeDigestOwnerIDLengthRule: SeasonalOvertimeDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOvertimeDigest) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal overtime digest.
    final class SeasonalOvertimeDigestValidator {
        var rules: [any SeasonalOvertimeDigestRule]

        init(rules: [any SeasonalOvertimeDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalOvertimeDigest) -> [String] {
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

        func requireValid(_ item: SeasonalOvertimeDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalOvertimeDigest]) -> [String: [String]] {
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

    static func defaultSeasonalOvertimeDigestValidator() -> SeasonalOvertimeDigestValidator {
        return SeasonalOvertimeDigestValidator(
            rules: [
                SeasonalOvertimeDigestNameLengthRule(maxLength: 3600),
                SeasonalOvertimeDigestPatientRefLengthRule(maxLength: 1000),
                SeasonalOvertimeDigestCodeLengthRule(maxLength: 1000),
                SeasonalOvertimeDigestCodePrefixRule(prefix: "REF"),
                SeasonalOvertimeDigestOwnerIDLengthRule(maxLength: 80),
            ]
        )
    }
}

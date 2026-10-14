import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual program bundle must pass. Check returns its problems, or none.
    protocol ManualProgramBundleRule {
        func check(_ item: ManualProgramBundle) -> [String]
    }

    final class ManualProgramBundleCodeLengthRule: ManualProgramBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualProgramBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualProgramBundlePhoneLengthRule: ManualProgramBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualProgramBundle) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualProgramBundleAllowedCodeRule: ManualProgramBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualProgramBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a manual program bundle.
    final class ManualProgramBundleValidator {
        var rules: [any ManualProgramBundleRule]

        init(rules: [any ManualProgramBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualProgramBundle) -> [String] {
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

        func requireValid(_ item: ManualProgramBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualProgramBundle]) -> [String: [String]] {
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

    static func defaultManualProgramBundleValidator() -> ManualProgramBundleValidator {
        return ManualProgramBundleValidator(
            rules: [
                ManualProgramBundleCodeLengthRule(maxLength: 64),
                ManualProgramBundlePhoneLengthRule(maxLength: 255),
                ManualProgramBundleAllowedCodeRule(allowed: []),
            ]
        )
    }
}

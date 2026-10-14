import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient program profile must pass. Check returns its problems, or none.
    protocol LenientProgramProfileRule {
        func check(_ item: LenientProgramProfile) -> [String]
    }

    final class LenientProgramProfileApprovedGuardRule: LenientProgramProfileRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientProgramProfile) -> [String] {
            if item.approved && (item.acuity > limit) {
                return ["acuity \(item.acuity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LenientProgramProfileRequiredPatientRefRule: LenientProgramProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProgramProfile) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProgramProfileTitleLengthRule: LenientProgramProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProgramProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientProgramProfileAllowedCodeRule: LenientProgramProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientProgramProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient program profile.
    final class LenientProgramProfileValidator {
        var rules: [any LenientProgramProfileRule]

        init(rules: [any LenientProgramProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProgramProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientProgramProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProgramProfile]) -> [String: [String]] {
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

    static func defaultLenientProgramProfileValidator() -> LenientProgramProfileValidator {
        return LenientProgramProfileValidator(
            rules: [
                LenientProgramProfileApprovedGuardRule(limit: 120),
                LenientProgramProfileRequiredPatientRefRule(message: "lenient program profile needs a value"),
                LenientProgramProfileTitleLengthRule(maxLength: 120),
                LenientProgramProfileAllowedCodeRule(allowed: []),
            ]
        )
    }
}

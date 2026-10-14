import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool notice must pass. Check returns its problems, or none.
    protocol FloatPoolNoticeRule {
        func check(_ item: FloatPoolNotice) -> [String]
    }

    final class FloatPoolNoticeActiveGuardRule: FloatPoolNoticeRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FloatPoolNotice) -> [String] {
            if item.active && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class FloatPoolNoticeRequiredCountryRule: FloatPoolNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolNotice) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolNoticePatientRefLengthRule: FloatPoolNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolNotice) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool notice.
    final class FloatPoolNoticeValidator {
        var rules: [any FloatPoolNoticeRule]

        init(rules: [any FloatPoolNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolNotice]) -> [String: [String]] {
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

    static func defaultFloatPoolNoticeValidator() -> FloatPoolNoticeValidator {
        return FloatPoolNoticeValidator(
            rules: [
                FloatPoolNoticeActiveGuardRule(limit: 80),
                FloatPoolNoticeRequiredCountryRule(message: "float pool notice needs an entry"),
                FloatPoolNoticePatientRefLengthRule(maxLength: 64),
            ]
        )
    }
}

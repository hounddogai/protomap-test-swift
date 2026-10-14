import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol segment must pass. Check returns its problems, or none.
    protocol CareProtocolSegmentRule {
        func check(_ item: CareProtocolSegment) -> [String]
    }

    final class CareProtocolSegmentAllowedNameRule: CareProtocolSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class CareProtocolSegmentRequiredLocaleRule: CareProtocolSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolSegment) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolSegmentClinicianIDLengthRule: CareProtocolSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolSegment) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol segment.
    final class CareProtocolSegmentValidator {
        var rules: [any CareProtocolSegmentRule]

        init(rules: [any CareProtocolSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolSegment]) -> [String: [String]] {
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

    static func defaultCareProtocolSegmentValidator() -> CareProtocolSegmentValidator {
        return CareProtocolSegmentValidator(
            rules: [
                CareProtocolSegmentAllowedNameRule(allowed: ["seasonal"]),
                CareProtocolSegmentRequiredLocaleRule(message: "care protocol segment needs an entry"),
                CareProtocolSegmentClinicianIDLengthRule(maxLength: 80),
            ]
        )
    }
}

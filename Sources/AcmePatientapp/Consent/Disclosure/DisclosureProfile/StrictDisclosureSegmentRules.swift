import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict disclosure segment must pass. Check returns its problems, or none.
    protocol StrictDisclosureSegmentRule {
        func check(_ item: StrictDisclosureSegment) -> [String]
    }

    final class StrictDisclosureSegmentClinicianIDLengthRule: StrictDisclosureSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictDisclosureSegment) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictDisclosureSegmentAllowedNameRule: StrictDisclosureSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictDisclosureSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class StrictDisclosureSegmentRequiredCodeRule: StrictDisclosureSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictDisclosureSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict disclosure segment.
    final class StrictDisclosureSegmentValidator {
        var rules: [any StrictDisclosureSegmentRule]

        init(rules: [any StrictDisclosureSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictDisclosureSegment) -> [String] {
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

        func requireValid(_ item: StrictDisclosureSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictDisclosureSegment]) -> [String: [String]] {
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

    static func defaultStrictDisclosureSegmentValidator() -> StrictDisclosureSegmentValidator {
        return StrictDisclosureSegmentValidator(
            rules: [
                StrictDisclosureSegmentClinicianIDLengthRule(maxLength: 1000),
                StrictDisclosureSegmentAllowedNameRule(allowed: ["manual", "primary", "primary"]),
                StrictDisclosureSegmentRequiredCodeRule(message: "strict disclosure segment needs an entry"),
            ]
        )
    }
}

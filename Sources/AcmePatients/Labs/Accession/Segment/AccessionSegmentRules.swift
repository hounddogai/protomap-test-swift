import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession segment must pass. Check returns its problems, or none.
    protocol AccessionSegmentRule {
        func check(_ item: AccessionSegment) -> [String]
    }

    final class AccessionSegmentUnitLengthRule: AccessionSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionSegment) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionSegmentCodePrefixRule: AccessionSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AccessionSegmentLabelLengthRule: AccessionSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionSegmentRequiredUnitRule: AccessionSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionSegment) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionSegmentAllowedPatientRefRule: AccessionSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a accession segment.
    final class AccessionSegmentValidator {
        var rules: [any AccessionSegmentRule]

        init(rules: [any AccessionSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionSegment) -> [String] {
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

        func requireValid(_ item: AccessionSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionSegment]) -> [String: [String]] {
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

    static func defaultAccessionSegmentValidator() -> AccessionSegmentValidator {
        return AccessionSegmentValidator(
            rules: [
                AccessionSegmentUnitLengthRule(maxLength: 3600),
                AccessionSegmentCodePrefixRule(prefix: "X"),
                AccessionSegmentLabelLengthRule(maxLength: 86400),
                AccessionSegmentRequiredUnitRule(message: "accession segment needs a value"),
                AccessionSegmentAllowedPatientRefRule(allowed: []),
            ]
        )
    }
}

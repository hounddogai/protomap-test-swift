import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary substitution notice must pass. Check returns its problems, or none.
    protocol PrimarySubstitutionNoticeRule {
        func check(_ item: PrimarySubstitutionNotice) -> [String]
    }

    final class PrimarySubstitutionNoticeRequiredRegionRule: PrimarySubstitutionNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySubstitutionNotice) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySubstitutionNoticeRequiredCodeRule: PrimarySubstitutionNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySubstitutionNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySubstitutionNoticeRequiredLabelRule: PrimarySubstitutionNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimarySubstitutionNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimarySubstitutionNoticeAllowedRegionRule: PrimarySubstitutionNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimarySubstitutionNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is below minimum"]
            }
            return []
        }
    }

    final class PrimarySubstitutionNoticeStartsAtRangeRule: PrimarySubstitutionNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimarySubstitutionNotice) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimarySubstitutionNoticeRegionLengthRule: PrimarySubstitutionNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySubstitutionNotice) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary substitution notice.
    final class PrimarySubstitutionNoticeValidator {
        var rules: [any PrimarySubstitutionNoticeRule]

        init(rules: [any PrimarySubstitutionNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySubstitutionNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimarySubstitutionNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySubstitutionNotice]) -> [String: [String]] {
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

    static func defaultPrimarySubstitutionNoticeValidator() -> PrimarySubstitutionNoticeValidator {
        return PrimarySubstitutionNoticeValidator(
            rules: [
                PrimarySubstitutionNoticeRequiredRegionRule(message: "primary substitution notice needs a value"),
                PrimarySubstitutionNoticeRequiredCodeRule(message: "primary substitution notice needs a value"),
                PrimarySubstitutionNoticeRequiredLabelRule(message: "primary substitution notice needs an entry"),
                PrimarySubstitutionNoticeAllowedRegionRule(allowed: []),
                PrimarySubstitutionNoticeStartsAtRangeRule(min: 16, max: 3600),
                PrimarySubstitutionNoticeRegionLengthRule(maxLength: 16),
            ]
        )
    }
}

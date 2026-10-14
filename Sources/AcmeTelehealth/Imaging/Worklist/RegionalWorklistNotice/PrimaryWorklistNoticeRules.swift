import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary worklist notice must pass. Check returns its problems, or none.
    protocol PrimaryWorklistNoticeRule {
        func check(_ item: PrimaryWorklistNotice) -> [String]
    }

    final class PrimaryWorklistNoticeRequiredLabelRule: PrimaryWorklistNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryWorklistNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryWorklistNoticeRequiredPayerRule: PrimaryWorklistNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryWorklistNotice) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryWorklistNoticeRateRangeRule: PrimaryWorklistNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryWorklistNotice) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryWorklistNoticeRequiredTimezoneRule: PrimaryWorklistNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryWorklistNotice) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryWorklistNoticeAllowedContactEmailRule: PrimaryWorklistNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryWorklistNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is expired"]
            }
            return []
        }
    }

    final class PrimaryWorklistNoticeMaximumRangeRule: PrimaryWorklistNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryWorklistNotice) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary worklist notice.
    final class PrimaryWorklistNoticeValidator {
        var rules: [any PrimaryWorklistNoticeRule]

        init(rules: [any PrimaryWorklistNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryWorklistNotice) -> [String] {
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

        func requireValid(_ item: PrimaryWorklistNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryWorklistNotice]) -> [String: [String]] {
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

    static func defaultPrimaryWorklistNoticeValidator() -> PrimaryWorklistNoticeValidator {
        return PrimaryWorklistNoticeValidator(
            rules: [
                PrimaryWorklistNoticeRequiredLabelRule(message: "primary worklist notice needs an entry"),
                PrimaryWorklistNoticeRequiredPayerRule(message: "primary worklist notice needs this field"),
                PrimaryWorklistNoticeRateRangeRule(min: 8.6, max: 2851.2),
                PrimaryWorklistNoticeRequiredTimezoneRule(message: "primary worklist notice needs this field"),
                PrimaryWorklistNoticeAllowedContactEmailRule(allowed: ["default", "manual", "adaptive"]),
                PrimaryWorklistNoticeMaximumRangeRule(min: 4.2, max: 4145.9),
            ]
        )
    }
}

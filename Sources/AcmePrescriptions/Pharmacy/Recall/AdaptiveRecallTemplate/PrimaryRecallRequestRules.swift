import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary recall request must pass. Check returns its problems, or none.
    protocol PrimaryRecallRequestRule {
        func check(_ item: PrimaryRecallRequest) -> [String]
    }

    final class PrimaryRecallRequestTitleLengthRule: PrimaryRecallRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRecallRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRecallRequestAllowedContactEmailRule: PrimaryRecallRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryRecallRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is below minimum"]
            }
            return []
        }
    }

    final class PrimaryRecallRequestContactEmailLengthRule: PrimaryRecallRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRecallRequest) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary recall request.
    final class PrimaryRecallRequestValidator {
        var rules: [any PrimaryRecallRequestRule]

        init(rules: [any PrimaryRecallRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRecallRequest) -> [String] {
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

        func requireValid(_ item: PrimaryRecallRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRecallRequest]) -> [String: [String]] {
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

    static func defaultPrimaryRecallRequestValidator() -> PrimaryRecallRequestValidator {
        return PrimaryRecallRequestValidator(
            rules: [
                PrimaryRecallRequestTitleLengthRule(maxLength: 32),
                PrimaryRecallRequestAllowedContactEmailRule(allowed: []),
                PrimaryRecallRequestContactEmailLengthRule(maxLength: 64),
            ]
        )
    }
}

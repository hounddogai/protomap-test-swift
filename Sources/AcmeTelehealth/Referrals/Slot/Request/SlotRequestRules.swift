import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot request must pass. Check returns its problems, or none.
    protocol SlotRequestRule {
        func check(_ item: SlotRequest) -> [String]
    }

    final class SlotRequestRequiredCountryRule: SlotRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotRequest) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotRequestCodeLengthRule: SlotRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotRequestApprovedGuardRule: SlotRequestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SlotRequest) -> [String] {
            if item.approved && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a slot request.
    final class SlotRequestValidator {
        var rules: [any SlotRequestRule]

        init(rules: [any SlotRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotRequest) -> [String] {
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

        func requireValid(_ item: SlotRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotRequest]) -> [String: [String]] {
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

    static func defaultSlotRequestValidator() -> SlotRequestValidator {
        return SlotRequestValidator(
            rules: [
                SlotRequestRequiredCountryRule(message: "slot request needs a value"),
                SlotRequestCodeLengthRule(maxLength: 86400),
                SlotRequestApprovedGuardRule(limit: 0.1),
            ]
        )
    }
}

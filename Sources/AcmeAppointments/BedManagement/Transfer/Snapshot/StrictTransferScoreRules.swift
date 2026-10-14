import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict transfer score must pass. Check returns its problems, or none.
    protocol StrictTransferScoreRule {
        func check(_ item: StrictTransferScore) -> [String]
    }

    final class StrictTransferScoreCodeLengthRule: StrictTransferScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictTransferScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictTransferScoreCopayRangeRule: StrictTransferScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictTransferScore) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictTransferScoreClinicianIDLengthRule: StrictTransferScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictTransferScore) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictTransferScoreRequiredClinicianIDRule: StrictTransferScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictTransferScore) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictTransferScoreAllowedCodeRule: StrictTransferScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictTransferScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class StrictTransferScoreCodePrefixRule: StrictTransferScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictTransferScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict transfer score.
    final class StrictTransferScoreValidator {
        var rules: [any StrictTransferScoreRule]

        init(rules: [any StrictTransferScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictTransferScore) -> [String] {
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

        func requireValid(_ item: StrictTransferScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictTransferScore]) -> [String: [String]] {
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

    static func defaultStrictTransferScoreValidator() -> StrictTransferScoreValidator {
        return StrictTransferScoreValidator(
            rules: [
                StrictTransferScoreCodeLengthRule(maxLength: 3600),
                StrictTransferScoreCopayRangeRule(min: 8.8, max: 2790.5),
                StrictTransferScoreClinicianIDLengthRule(maxLength: 16),
                StrictTransferScoreRequiredClinicianIDRule(message: "strict transfer score needs an entry"),
                StrictTransferScoreAllowedCodeRule(allowed: ["legacy", "tiered"]),
                StrictTransferScoreCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}

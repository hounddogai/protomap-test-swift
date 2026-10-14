import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel claim must pass. Check returns its problems, or none.
    protocol PanelClaimRule {
        func check(_ item: PanelClaim) -> [String]
    }

    final class PanelClaimPhoneLengthRule: PanelClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelClaim) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelClaimCodePrefixRule: PanelClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelClaimScoreRangeRule: PanelClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelClaim) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PanelClaimRequiredLabelRule: PanelClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelClaim) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel claim.
    final class PanelClaimValidator {
        var rules: [any PanelClaimRule]

        init(rules: [any PanelClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelClaim]) -> [String: [String]] {
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

    static func defaultPanelClaimValidator() -> PanelClaimValidator {
        return PanelClaimValidator(
            rules: [
                PanelClaimPhoneLengthRule(maxLength: 120),
                PanelClaimCodePrefixRule(prefix: "REF"),
                PanelClaimScoreRangeRule(min: 6.7, max: 3801.0),
                PanelClaimRequiredLabelRule(message: "panel claim needs this field"),
            ]
        )
    }
}

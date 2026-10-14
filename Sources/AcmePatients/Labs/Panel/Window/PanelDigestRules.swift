import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel digest must pass. Check returns its problems, or none.
    protocol PanelDigestRule {
        func check(_ item: PanelDigest) -> [String]
    }

    final class PanelDigestNameLengthRule: PanelDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelDigestRequiredClinicianIDRule: PanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelDigest) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelDigestDescriptionLengthRule: PanelDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelDigest) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelDigestAmountRangeRule: PanelDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelDigest) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PanelDigestRequiredNameRule: PanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel digest.
    final class PanelDigestValidator {
        var rules: [any PanelDigestRule]

        init(rules: [any PanelDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelDigest) -> [String] {
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

        func requireValid(_ item: PanelDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelDigest]) -> [String: [String]] {
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

    static func defaultPanelDigestValidator() -> PanelDigestValidator {
        return PanelDigestValidator(
            rules: [
                PanelDigestNameLengthRule(maxLength: 3600),
                PanelDigestRequiredClinicianIDRule(message: "panel digest needs an entry"),
                PanelDigestDescriptionLengthRule(maxLength: 16),
                PanelDigestAmountRangeRule(min: 1.8, max: 4238.5),
                PanelDigestRequiredNameRule(message: "panel digest needs an entry"),
            ]
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance snapshot must pass. Check returns its problems, or none.
    protocol RemittanceSnapshotRule {
        func check(_ item: RemittanceSnapshot) -> [String]
    }

    final class RemittanceSnapshotVisibleGuardRule: RemittanceSnapshotRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RemittanceSnapshot) -> [String] {
            if item.visible && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class RemittanceSnapshotRequiredNameRule: RemittanceSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceSnapshotCountryLengthRule: RemittanceSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceSnapshot) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceSnapshotCodeLengthRule: RemittanceSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceSnapshotRequiredCountryRule: RemittanceSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceSnapshot) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance snapshot.
    final class RemittanceSnapshotValidator {
        var rules: [any RemittanceSnapshotRule]

        init(rules: [any RemittanceSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceSnapshot]) -> [String: [String]] {
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

    static func defaultRemittanceSnapshotValidator() -> RemittanceSnapshotValidator {
        return RemittanceSnapshotValidator(
            rules: [
                RemittanceSnapshotVisibleGuardRule(limit: 0.8),
                RemittanceSnapshotRequiredNameRule(message: "remittance snapshot needs this field"),
                RemittanceSnapshotCountryLengthRule(maxLength: 86400),
                RemittanceSnapshotCodeLengthRule(maxLength: 80),
                RemittanceSnapshotRequiredCountryRule(message: "remittance snapshot needs a value"),
            ]
        )
    }
}

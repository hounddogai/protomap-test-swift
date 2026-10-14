import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality record must pass. Check returns its problems, or none.
    protocol ModalityRecordRule {
        func check(_ item: ModalityRecord) -> [String]
    }

    final class ModalityRecordRequiredExternalRefRule: ModalityRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityRecord) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityRecordMaximumRangeRule: ModalityRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityRecord) -> [String] {
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

    final class ModalityRecordMinimumRangeRule: ModalityRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityRecord) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityRecordAllowedCodeRule: ModalityRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalityRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class ModalityRecordLabelLengthRule: ModalityRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityRecordRequiredOwnerIDRule: ModalityRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityRecord) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a modality record.
    final class ModalityRecordValidator {
        var rules: [any ModalityRecordRule]

        init(rules: [any ModalityRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityRecord) -> [String] {
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

        func requireValid(_ item: ModalityRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityRecord]) -> [String: [String]] {
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

    static func defaultModalityRecordValidator() -> ModalityRecordValidator {
        return ModalityRecordValidator(
            rules: [
                ModalityRecordRequiredExternalRefRule(message: "modality record needs an entry"),
                ModalityRecordMaximumRangeRule(min: 3.9, max: 1598.6),
                ModalityRecordMinimumRangeRule(min: 8.8, max: 2172.3),
                ModalityRecordAllowedCodeRule(allowed: []),
                ModalityRecordLabelLengthRule(maxLength: 80),
                ModalityRecordRequiredOwnerIDRule(message: "modality record needs an entry"),
            ]
        )
    }
}

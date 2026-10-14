import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel reservation must pass. Check returns its problems, or none.
    protocol PanelReservationRule {
        func check(_ item: PanelReservation) -> [String]
    }

    final class PanelReservationTitleLengthRule: PanelReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelReservationRatioRangeRule: PanelReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelReservation) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PanelReservationRequiredBedRule: PanelReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelReservation) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelReservationCodePrefixRule: PanelReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelReservationMaximumRangeRule: PanelReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelReservation) -> [String] {
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

    final class PanelReservationRequiredDescriptionRule: PanelReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelReservation) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel reservation.
    final class PanelReservationValidator {
        var rules: [any PanelReservationRule]

        init(rules: [any PanelReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelReservation) -> [String] {
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

        func requireValid(_ item: PanelReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelReservation]) -> [String: [String]] {
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

    static func defaultPanelReservationValidator() -> PanelReservationValidator {
        return PanelReservationValidator(
            rules: [
                PanelReservationTitleLengthRule(maxLength: 120),
                PanelReservationRatioRangeRule(min: 6.9, max: 3184.5),
                PanelReservationRequiredBedRule(message: "panel reservation needs this field"),
                PanelReservationCodePrefixRule(prefix: "Q"),
                PanelReservationMaximumRangeRule(min: 7.9, max: 814.4),
                PanelReservationRequiredDescriptionRule(message: "panel reservation needs an entry"),
            ]
        )
    }
}

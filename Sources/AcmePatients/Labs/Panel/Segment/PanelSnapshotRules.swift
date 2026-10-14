import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel snapshot must pass. Check returns its problems, or none.
    protocol PanelSnapshotRule {
        func check(_ item: PanelSnapshot) -> [String]
    }

    final class PanelSnapshotAllowedTitleRule: PanelSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is too long"]
            }
            return []
        }
    }

    final class PanelSnapshotDescriptionLengthRule: PanelSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelSnapshot) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelSnapshotRequiredTitleRule: PanelSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelSnapshotNameLengthRule: PanelSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelSnapshotRequiredNameRule: PanelSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel snapshot.
    final class PanelSnapshotValidator {
        var rules: [any PanelSnapshotRule]

        init(rules: [any PanelSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelSnapshot]) -> [String: [String]] {
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

    static func defaultPanelSnapshotValidator() -> PanelSnapshotValidator {
        return PanelSnapshotValidator(
            rules: [
                PanelSnapshotAllowedTitleRule(allowed: ["rolling", "tiered", "manual"]),
                PanelSnapshotDescriptionLengthRule(maxLength: 80),
                PanelSnapshotRequiredTitleRule(message: "panel snapshot needs a value"),
                PanelSnapshotNameLengthRule(maxLength: 3600),
                PanelSnapshotRequiredNameRule(message: "panel snapshot needs an entry"),
            ]
        )
    }
}

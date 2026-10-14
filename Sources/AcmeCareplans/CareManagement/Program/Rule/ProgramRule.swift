import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program rule is in its life cycle.
    enum ProgramRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One program rule, with what the planners need to act on it.
    final class ProgramRule {
        var code: String
        var name: String
        var channel: String
        var attributes: [String: String]
        var tags: [String]
        var payer: String
        var locale: String
        var timezone: String
        var procedureCode: String
        var segment: String
        var score: Double
        var status: ProgramRuleStatus

        init(code: String, name: String, channel: String, attributes: [String: String], tags: [String], payer: String, locale: String, timezone: String, procedureCode: String, segment: String, score: Double, status: ProgramRuleStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.attributes = attributes
            self.tags = tags
            self.payer = payer
            self.locale = locale
            self.timezone = timezone
            self.procedureCode = procedureCode
            self.segment = segment
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramRuleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ProgramRuleStatus.active || next == ProgramRuleStatus.closed
            case .active:
                return next == ProgramRuleStatus.suspended || next == ProgramRuleStatus.closed
            case .suspended:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("program rule") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ProgramRule {
            return ProgramRule(
                code: code,
                name: name,
                channel: channel,
                attributes: attributes,
                tags: tags,
                payer: payer,
                locale: locale,
                timezone: timezone,
                procedureCode: procedureCode,
                segment: segment,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a program rule in status draft.
    static func newProgramRule(_ code: String, name: String) -> ProgramRule {
        return ProgramRule(
            code: code,
            name: name,
            channel: "",
            attributes: [:],
            tags: [],
            payer: "",
            locale: "",
            timezone: "",
            procedureCode: "",
            segment: "",
            score: 0.0,
            status: ProgramRuleStatus.draft
        )
    }
}

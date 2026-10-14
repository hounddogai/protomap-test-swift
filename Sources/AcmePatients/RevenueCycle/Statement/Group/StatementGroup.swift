import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement group is in its life cycle.
    enum StatementGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A statement group as the statement team keeps it.
    final class StatementGroup {
        var code: String
        var title: String
        var startsAt: Int
        var allergy: String
        var tags: [String]
        var diagnosisCode: String
        var timezone: String
        var status: StatementGroupStatus

        init(code: String, title: String, startsAt: Int, allergy: String, tags: [String], diagnosisCode: String, timezone: String, status: StatementGroupStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.allergy = allergy
            self.tags = tags
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementGroupStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == StatementGroupStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StatementGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("statement group") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> StatementGroup {
            return StatementGroup(
                code: code,
                title: title,
                startsAt: startsAt,
                allergy: allergy,
                tags: tags,
                diagnosisCode: diagnosisCode,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a statement group in status proposed.
    static func newStatementGroup(_ code: String, title: String) -> StatementGroup {
        return StatementGroup(
            code: code,
            title: title,
            startsAt: 0,
            allergy: "",
            tags: [],
            diagnosisCode: "",
            timezone: "",
            status: StatementGroupStatus.proposed
        )
    }
}

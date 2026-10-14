import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional eligibility notice is in its life cycle.
    enum RegionalEligibilityNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional eligibility notice as the eligibility team keeps it.
    final class RegionalEligibilityNotice {
        var code: String
        var title: String
        var maximum: Double
        var expiresAt: Int
        var visitMinutes: Int
        var attributes: [String: String]
        var visible: Bool
        var archived: Bool
        var weight: Double
        var version: Int
        var unit: String
        var status: RegionalEligibilityNoticeStatus

        init(code: String, title: String, maximum: Double, expiresAt: Int, visitMinutes: Int, attributes: [String: String], visible: Bool, archived: Bool, weight: Double, version: Int, unit: String, status: RegionalEligibilityNoticeStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.expiresAt = expiresAt
            self.visitMinutes = visitMinutes
            self.attributes = attributes
            self.visible = visible
            self.archived = archived
            self.weight = weight
            self.version = version
            self.unit = unit
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

        func canMoveTo(_ next: RegionalEligibilityNoticeStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalEligibilityNoticeStatus.active
            case .pending:
                return next == RegionalEligibilityNoticeStatus.active || next == RegionalEligibilityNoticeStatus.suspended
            case .active:
                return next == RegionalEligibilityNoticeStatus.suspended
            case .suspended:
                return next == RegionalEligibilityNoticeStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalEligibilityNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional eligibility notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func effectiveVolume() -> Double {
            return ((maximum + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalEligibilityNotice {
            return RegionalEligibilityNotice(
                code: code,
                title: title,
                maximum: maximum,
                expiresAt: expiresAt,
                visitMinutes: visitMinutes,
                attributes: attributes,
                visible: visible,
                archived: archived,
                weight: weight,
                version: version,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional eligibility notice in status draft.
    static func newRegionalEligibilityNotice(_ code: String, title: String) -> RegionalEligibilityNotice {
        return RegionalEligibilityNotice(
            code: code,
            title: title,
            maximum: 0.0,
            expiresAt: 0,
            visitMinutes: 0,
            attributes: [:],
            visible: false,
            archived: false,
            weight: 0.0,
            version: 0,
            unit: "",
            status: RegionalEligibilityNoticeStatus.draft
        )
    }
}

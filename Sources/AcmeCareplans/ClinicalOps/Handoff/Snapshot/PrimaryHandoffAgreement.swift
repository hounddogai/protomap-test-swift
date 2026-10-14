import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary handoff agreement is in its life cycle.
    enum PrimaryHandoffAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One primary handoff agreement, with what the planners need to act on it.
    final class PrimaryHandoffAgreement {
        var code: String
        var title: String
        var discount: Double
        var expiresAt: Int
        var attributes: [String: String]
        var visible: Bool
        var priority: Int
        var limit: Int
        var channel: String
        var notes: String
        var country: String
        var status: PrimaryHandoffAgreementStatus

        init(code: String, title: String, discount: Double, expiresAt: Int, attributes: [String: String], visible: Bool, priority: Int, limit: Int, channel: String, notes: String, country: String, status: PrimaryHandoffAgreementStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.expiresAt = expiresAt
            self.attributes = attributes
            self.visible = visible
            self.priority = priority
            self.limit = limit
            self.channel = channel
            self.notes = notes
            self.country = country
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

        func canMoveTo(_ next: PrimaryHandoffAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryHandoffAgreementStatus.suspended || next == PrimaryHandoffAgreementStatus.closed
            case .pending:
                return next == PrimaryHandoffAgreementStatus.active || next == PrimaryHandoffAgreementStatus.suspended
            case .active:
                return next == PrimaryHandoffAgreementStatus.closed
            case .suspended:
                return next == PrimaryHandoffAgreementStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryHandoffAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary handoff agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
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

        func projectedExposure() -> Double {
            return ((discount + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryHandoffAgreement {
            return PrimaryHandoffAgreement(
                code: code,
                title: title,
                discount: discount,
                expiresAt: expiresAt,
                attributes: attributes,
                visible: visible,
                priority: priority,
                limit: limit,
                channel: channel,
                notes: notes,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary handoff agreement in status draft.
    static func newPrimaryHandoffAgreement(_ code: String, title: String) -> PrimaryHandoffAgreement {
        return PrimaryHandoffAgreement(
            code: code,
            title: title,
            discount: 0.0,
            expiresAt: 0,
            attributes: [:],
            visible: false,
            priority: 0,
            limit: 0,
            channel: "",
            notes: "",
            country: "",
            status: PrimaryHandoffAgreementStatus.draft
        )
    }
}

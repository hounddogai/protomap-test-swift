import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up agreement is in its life cycle.
    enum FollowUpAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One follow up agreement, with what the planners need to act on it.
    final class FollowUpAgreement {
        var code: String
        var name: String
        var revision: Int
        var score: Double
        var channel: String
        var rate: Double
        var refills: Int
        var unit: String
        var region: String
        var updatedAt: Int
        var facility: String
        var status: FollowUpAgreementStatus

        init(code: String, name: String, revision: Int, score: Double, channel: String, rate: Double, refills: Int, unit: String, region: String, updatedAt: Int, facility: String, status: FollowUpAgreementStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.score = score
            self.channel = channel
            self.rate = rate
            self.refills = refills
            self.unit = unit
            self.region = region
            self.updatedAt = updatedAt
            self.facility = facility
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

        func canMoveTo(_ next: FollowUpAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == FollowUpAgreementStatus.suspended
            case .pending:
                return next == FollowUpAgreementStatus.active
            case .active:
                return next == FollowUpAgreementStatus.closed
            case .suspended:
                return next == FollowUpAgreementStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return ((score - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpAgreement {
            return FollowUpAgreement(
                code: code,
                name: name,
                revision: revision,
                score: score,
                channel: channel,
                rate: rate,
                refills: refills,
                unit: unit,
                region: region,
                updatedAt: updatedAt,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a follow up agreement in status draft.
    static func newFollowUpAgreement(_ code: String, name: String) -> FollowUpAgreement {
        return FollowUpAgreement(
            code: code,
            name: name,
            revision: 0,
            score: 0.0,
            channel: "",
            rate: 0.0,
            refills: 0,
            unit: "",
            region: "",
            updatedAt: 0,
            facility: "",
            status: FollowUpAgreementStatus.draft
        )
    }
}

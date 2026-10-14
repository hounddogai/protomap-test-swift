import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up baseline is in its life cycle.
    enum FollowUpBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A follow up baseline as the follow up team keeps it.
    final class FollowUpBaseline {
        var code: String
        var title: String
        var limit: Int
        var copay: Double
        var procedureCode: String
        var ward: String
        var createdAt: Int
        var weight: Double
        var pinned: Bool
        var country: String
        var status: FollowUpBaselineStatus

        init(code: String, title: String, limit: Int, copay: Double, procedureCode: String, ward: String, createdAt: Int, weight: Double, pinned: Bool, country: String, status: FollowUpBaselineStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.copay = copay
            self.procedureCode = procedureCode
            self.ward = ward
            self.createdAt = createdAt
            self.weight = weight
            self.pinned = pinned
            self.country = country
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

        func canMoveTo(_ next: FollowUpBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == FollowUpBaselineStatus.withdrawn
            case .rejected:
                return next == FollowUpBaselineStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netExposure() -> Double {
            return (Double(createdAt) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpBaseline {
            return FollowUpBaseline(
                code: code,
                title: title,
                limit: limit,
                copay: copay,
                procedureCode: procedureCode,
                ward: ward,
                createdAt: createdAt,
                weight: weight,
                pinned: pinned,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a follow up baseline in status proposed.
    static func newFollowUpBaseline(_ code: String, title: String) -> FollowUpBaseline {
        return FollowUpBaseline(
            code: code,
            title: title,
            limit: 0,
            copay: 0.0,
            procedureCode: "",
            ward: "",
            createdAt: 0,
            weight: 0.0,
            pinned: false,
            country: "",
            status: FollowUpBaselineStatus.proposed
        )
    }
}

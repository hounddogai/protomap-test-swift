import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure score is in its life cycle.
    enum DisclosureScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A disclosure score as the disclosure team keeps it.
    final class DisclosureScore {
        var code: String
        var title: String
        var limit: Int
        var ward: String
        var visitMinutes: Int
        var pinned: Bool
        var rate: Double
        var copay: Double
        var ceiling: Double
        var status: DisclosureScoreStatus

        init(code: String, title: String, limit: Int, ward: String, visitMinutes: Int, pinned: Bool, rate: Double, copay: Double, ceiling: Double, status: DisclosureScoreStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.pinned = pinned
            self.rate = rate
            self.copay = copay
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DisclosureScoreStatus) -> Bool {
            switch status {
            case .requested:
                return next == DisclosureScoreStatus.revoked || next == DisclosureScoreStatus.expired
            case .granted:
                return next == DisclosureScoreStatus.revoked || next == DisclosureScoreStatus.expired
            case .revoked:
                return next == DisclosureScoreStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveVolume() -> Double {
            return ((ceiling + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureScore {
            return DisclosureScore(
                code: code,
                title: title,
                limit: limit,
                ward: ward,
                visitMinutes: visitMinutes,
                pinned: pinned,
                rate: rate,
                copay: copay,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a disclosure score in status requested.
    static func newDisclosureScore(_ code: String, title: String) -> DisclosureScore {
        return DisclosureScore(
            code: code,
            title: title,
            limit: 0,
            ward: "",
            visitMinutes: 0,
            pinned: false,
            rate: 0.0,
            copay: 0.0,
            ceiling: 0.0,
            status: DisclosureScoreStatus.requested
        )
    }
}

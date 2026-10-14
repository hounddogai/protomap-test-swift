import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance baseline is in its life cycle.
    enum RemittanceBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A remittance baseline as the remittance team keeps it.
    final class RemittanceBaseline {
        var code: String
        var title: String
        var locale: String
        var reviewer: String
        var updatedAt: Int
        var ownerID: String
        var patientRef: String
        var status: RemittanceBaselineStatus

        init(code: String, title: String, locale: String, reviewer: String, updatedAt: Int, ownerID: String, patientRef: String, status: RemittanceBaselineStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.reviewer = reviewer
            self.updatedAt = updatedAt
            self.ownerID = ownerID
            self.patientRef = patientRef
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

        func canMoveTo(_ next: RemittanceBaselineStatus) -> Bool {
            switch status {
            case .requested:
                return next == RemittanceBaselineStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == RemittanceBaselineStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> RemittanceBaseline {
            return RemittanceBaseline(
                code: code,
                title: title,
                locale: locale,
                reviewer: reviewer,
                updatedAt: updatedAt,
                ownerID: ownerID,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a remittance baseline in status requested.
    static func newRemittanceBaseline(_ code: String, title: String) -> RemittanceBaseline {
        return RemittanceBaseline(
            code: code,
            title: title,
            locale: "",
            reviewer: "",
            updatedAt: 0,
            ownerID: "",
            patientRef: "",
            status: RemittanceBaselineStatus.requested
        )
    }
}

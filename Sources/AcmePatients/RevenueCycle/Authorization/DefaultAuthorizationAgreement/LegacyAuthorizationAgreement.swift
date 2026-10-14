import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy authorization agreement is in its life cycle.
    enum LegacyAuthorizationAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One legacy authorization agreement, with what the planners need to act on it.
    final class LegacyAuthorizationAgreement {
        var code: String
        var title: String
        var externalRef: String
        var copay: Double
        var version: Int
        var updatedAt: Int
        var ward: String
        var visitMinutes: Int
        var ratio: Double
        var status: LegacyAuthorizationAgreementStatus

        init(code: String, title: String, externalRef: String, copay: Double, version: Int, updatedAt: Int, ward: String, visitMinutes: Int, ratio: Double, status: LegacyAuthorizationAgreementStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.copay = copay
            self.version = version
            self.updatedAt = updatedAt
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.ratio = ratio
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

        func canMoveTo(_ next: LegacyAuthorizationAgreementStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LegacyAuthorizationAgreementStatus.suspended
            case .active:
                return next == LegacyAuthorizationAgreementStatus.closed
            case .suspended:
                return next == LegacyAuthorizationAgreementStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAuthorizationAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy authorization agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return (ratio * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAuthorizationAgreement {
            return LegacyAuthorizationAgreement(
                code: code,
                title: title,
                externalRef: externalRef,
                copay: copay,
                version: version,
                updatedAt: updatedAt,
                ward: ward,
                visitMinutes: visitMinutes,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy authorization agreement in status draft.
    static func newLegacyAuthorizationAgreement(_ code: String, title: String) -> LegacyAuthorizationAgreement {
        return LegacyAuthorizationAgreement(
            code: code,
            title: title,
            externalRef: "",
            copay: 0.0,
            version: 0,
            updatedAt: 0,
            ward: "",
            visitMinutes: 0,
            ratio: 0.0,
            status: LegacyAuthorizationAgreementStatus.draft
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive revocation exception is in its life cycle.
    enum AdaptiveRevocationExceptionStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive revocation exception as the revocation team keeps it.
    final class AdaptiveRevocationException {
        var code: String
        var name: String
        var retries: Int
        var margin: Double
        var visible: Bool
        var status: AdaptiveRevocationExceptionStatus

        init(code: String, name: String, retries: Int, margin: Double, visible: Bool, status: AdaptiveRevocationExceptionStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.margin = margin
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveRevocationExceptionStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveRevocationExceptionStatus.archived
            case .inReview:
                return next == AdaptiveRevocationExceptionStatus.resolved || next == AdaptiveRevocationExceptionStatus.archived
            case .resolved:
                return next == AdaptiveRevocationExceptionStatus.archived
            case .reopened:
                return next == AdaptiveRevocationExceptionStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRevocationExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive revocation exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive revocation exception") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(retries) + margin) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRevocationException {
            return AdaptiveRevocationException(
                code: code,
                name: name,
                retries: retries,
                margin: margin,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive revocation exception in status open.
    static func newAdaptiveRevocationException(_ code: String, name: String) -> AdaptiveRevocationException {
        return AdaptiveRevocationException(
            code: code,
            name: name,
            retries: 0,
            margin: 0.0,
            visible: false,
            status: AdaptiveRevocationExceptionStatus.`open`
        )
    }
}

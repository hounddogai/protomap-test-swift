import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback transfer request is in its life cycle.
    enum FallbackTransferRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One fallback transfer request, with what the planners need to act on it.
    final class FallbackTransferRequest {
        var code: String
        var title: String
        var discount: Double
        var visitMinutes: Int
        var endsAt: Int
        var status: FallbackTransferRequestStatus

        init(code: String, title: String, discount: Double, visitMinutes: Int, endsAt: Int, status: FallbackTransferRequestStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.visitMinutes = visitMinutes
            self.endsAt = endsAt
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

        func canMoveTo(_ next: FallbackTransferRequestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FallbackTransferRequestStatus.reopened || next == FallbackTransferRequestStatus.archived
            case .reopened:
                return next == FallbackTransferRequestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackTransferRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback transfer request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netLoad() -> Double {
            return (Double(visitMinutes) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> FallbackTransferRequest {
            return FallbackTransferRequest(
                code: code,
                title: title,
                discount: discount,
                visitMinutes: visitMinutes,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback transfer request in status open.
    static func newFallbackTransferRequest(_ code: String, title: String) -> FallbackTransferRequest {
        return FallbackTransferRequest(
            code: code,
            title: title,
            discount: 0.0,
            visitMinutes: 0,
            endsAt: 0,
            status: FallbackTransferRequestStatus.`open`
        )
    }
}

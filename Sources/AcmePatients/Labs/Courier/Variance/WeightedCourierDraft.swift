import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted courier draft is in its life cycle.
    enum WeightedCourierDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted courier draft as the courier team keeps it.
    final class WeightedCourierDraft {
        var code: String
        var title: String
        var updatedAt: Int
        var quantity: Int
        var durationMinutes: Int
        var status: WeightedCourierDraftStatus

        init(code: String, title: String, updatedAt: Int, quantity: Int, durationMinutes: Int, status: WeightedCourierDraftStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.quantity = quantity
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: WeightedCourierDraftStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedCourierDraftStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WeightedCourierDraftStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedCourierDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted courier draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netLoad() -> Double {
            return ((Double(durationMinutes) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCourierDraft {
            return WeightedCourierDraft(
                code: code,
                title: title,
                updatedAt: updatedAt,
                quantity: quantity,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted courier draft in status requested.
    static func newWeightedCourierDraft(_ code: String, title: String) -> WeightedCourierDraft {
        return WeightedCourierDraft(
            code: code,
            title: title,
            updatedAt: 0,
            quantity: 0,
            durationMinutes: 0,
            status: WeightedCourierDraftStatus.requested
        )
    }
}

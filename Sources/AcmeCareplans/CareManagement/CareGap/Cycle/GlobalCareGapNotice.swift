import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global care gap notice is in its life cycle.
    enum GlobalCareGapNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global care gap notice, with what the planners need to act on it.
    final class GlobalCareGapNotice {
        var code: String
        var name: String
        var margin: Double
        var archived: Bool
        var dosageMg: Double
        var status: GlobalCareGapNoticeStatus

        init(code: String, name: String, margin: Double, archived: Bool, dosageMg: Double, status: GlobalCareGapNoticeStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.archived = archived
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: GlobalCareGapNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalCareGapNoticeStatus.granted || next == GlobalCareGapNoticeStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == GlobalCareGapNoticeStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCareGapNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global care gap notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global care gap notice") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((dosageMg - margin) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCareGapNotice {
            return GlobalCareGapNotice(
                code: code,
                name: name,
                margin: margin,
                archived: archived,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global care gap notice in status requested.
    static func newGlobalCareGapNotice(_ code: String, name: String) -> GlobalCareGapNotice {
        return GlobalCareGapNotice(
            code: code,
            name: name,
            margin: 0.0,
            archived: false,
            dosageMg: 0.0,
            status: GlobalCareGapNoticeStatus.requested
        )
    }
}

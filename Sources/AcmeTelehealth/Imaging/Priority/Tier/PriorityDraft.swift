import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority draft is in its life cycle.
    enum PriorityDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a priority draft and its current status.
    final class PriorityDraft {
        var code: String
        var title: String
        var visitMinutes: Int
        var name: String
        var expiresAt: Int
        var dosageMg: Double
        var ratio: Double
        var label: String
        var minimum: Double
        var status: PriorityDraftStatus

        init(code: String, title: String, visitMinutes: Int, name: String, expiresAt: Int, dosageMg: Double, ratio: Double, label: String, minimum: Double, status: PriorityDraftStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.name = name
            self.expiresAt = expiresAt
            self.dosageMg = dosageMg
            self.ratio = ratio
            self.label = label
            self.minimum = minimum
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

        func canMoveTo(_ next: PriorityDraftStatus) -> Bool {
            switch status {
            case .requested:
                return next == PriorityDraftStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func netLoad() -> Double {
            return ((Double(expiresAt) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> PriorityDraft {
            return PriorityDraft(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                name: name,
                expiresAt: expiresAt,
                dosageMg: dosageMg,
                ratio: ratio,
                label: label,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a priority draft in status requested.
    static func newPriorityDraft(_ code: String, title: String) -> PriorityDraft {
        return PriorityDraft(
            code: code,
            title: title,
            visitMinutes: 0,
            name: "",
            expiresAt: 0,
            dosageMg: 0.0,
            ratio: 0.0,
            label: "",
            minimum: 0.0,
            status: PriorityDraftStatus.requested
        )
    }
}

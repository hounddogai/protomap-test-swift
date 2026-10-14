import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default handoff draft is in its life cycle.
    enum DefaultHandoffDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One default handoff draft, with what the planners need to act on it.
    final class DefaultHandoffDraft {
        var code: String
        var title: String
        var windowDays: Int
        var diagnosisCode: String
        var maximum: Double
        var segment: String
        var approved: Bool
        var visible: Bool
        var active: Bool
        var status: DefaultHandoffDraftStatus

        init(code: String, title: String, windowDays: Int, diagnosisCode: String, maximum: Double, segment: String, approved: Bool, visible: Bool, active: Bool, status: DefaultHandoffDraftStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.diagnosisCode = diagnosisCode
            self.maximum = maximum
            self.segment = segment
            self.approved = approved
            self.visible = visible
            self.active = active
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

        func canMoveTo(_ next: DefaultHandoffDraftStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DefaultHandoffDraftStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultHandoffDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default handoff draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default handoff draft") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((maximum + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultHandoffDraft {
            return DefaultHandoffDraft(
                code: code,
                title: title,
                windowDays: windowDays,
                diagnosisCode: diagnosisCode,
                maximum: maximum,
                segment: segment,
                approved: approved,
                visible: visible,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a default handoff draft in status requested.
    static func newDefaultHandoffDraft(_ code: String, title: String) -> DefaultHandoffDraft {
        return DefaultHandoffDraft(
            code: code,
            title: title,
            windowDays: 0,
            diagnosisCode: "",
            maximum: 0.0,
            segment: "",
            approved: false,
            visible: false,
            active: false,
            status: DefaultHandoffDraftStatus.requested
        )
    }
}

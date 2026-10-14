import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality override is in its life cycle.
    enum ModalityOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a modality override and its current status.
    final class ModalityOverride {
        var code: String
        var name: String
        var revision: Int
        var limit: Int
        var active: Bool
        var phone: String
        var version: Int
        var label: String
        var windowDays: Int
        var visible: Bool
        var status: ModalityOverrideStatus

        init(code: String, name: String, revision: Int, limit: Int, active: Bool, phone: String, version: Int, label: String, windowDays: Int, visible: Bool, status: ModalityOverrideStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.limit = limit
            self.active = active
            self.phone = phone
            self.version = version
            self.label = label
            self.windowDays = windowDays
            self.visible = visible
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

        func canMoveTo(_ next: ModalityOverrideStatus) -> Bool {
            switch status {
            case .draft:
                return next == ModalityOverrideStatus.pending || next == ModalityOverrideStatus.closed
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ModalityOverrideStatus.closed
            case .suspended:
                return next == ModalityOverrideStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return ((Double(version) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityOverride {
            return ModalityOverride(
                code: code,
                name: name,
                revision: revision,
                limit: limit,
                active: active,
                phone: phone,
                version: version,
                label: label,
                windowDays: windowDays,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a modality override in status draft.
    static func newModalityOverride(_ code: String, name: String) -> ModalityOverride {
        return ModalityOverride(
            code: code,
            name: name,
            revision: 0,
            limit: 0,
            active: false,
            phone: "",
            version: 0,
            label: "",
            windowDays: 0,
            visible: false,
            status: ModalityOverrideStatus.draft
        )
    }
}

import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped panel audit is in its life cycle.
    enum CappedPanelAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a capped panel audit and its current status.
    final class CappedPanelAudit {
        var code: String
        var name: String
        var label: String
        var archived: Bool
        var discount: Double
        var ownerID: String
        var visible: Bool
        var status: CappedPanelAuditStatus

        init(code: String, name: String, label: String, archived: Bool, discount: Double, ownerID: String, visible: Bool, status: CappedPanelAuditStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.archived = archived
            self.discount = discount
            self.ownerID = ownerID
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedPanelAuditStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedPanelAuditStatus.queued
            case .queued:
                return next == CappedPanelAuditStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CappedPanelAuditStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedPanelAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped panel audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped panel audit") \(code)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> CappedPanelAudit {
            return CappedPanelAudit(
                code: code,
                name: name,
                label: label,
                archived: archived,
                discount: discount,
                ownerID: ownerID,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped panel audit in status new.
    static func newCappedPanelAudit(_ code: String, name: String) -> CappedPanelAudit {
        return CappedPanelAudit(
            code: code,
            name: name,
            label: "",
            archived: false,
            discount: 0.0,
            ownerID: "",
            visible: false,
            status: CappedPanelAuditStatus.new
        )
    }
}

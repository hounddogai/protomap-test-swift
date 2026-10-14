import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel target is in its life cycle.
    enum PanelTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A panel target. Its code is unique within a tenant.
    final class PanelTarget {
        var code: String
        var title: String
        var approved: Bool
        var refills: Int
        var budget: Double
        var status: PanelTargetStatus

        init(code: String, title: String, approved: Bool, refills: Int, budget: Double, status: PanelTargetStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.refills = refills
            self.budget = budget
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

        func canMoveTo(_ next: PanelTargetStatus) -> Bool {
            switch status {
            case .draft:
                return next == PanelTargetStatus.closed
            case .pending:
                return next == PanelTargetStatus.active
            case .active:
                return next == PanelTargetStatus.closed
            case .suspended:
                return next == PanelTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return ((budget + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> PanelTarget {
            return PanelTarget(
                code: code,
                title: title,
                approved: approved,
                refills: refills,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a panel target in status draft.
    static func newPanelTarget(_ code: String, title: String) -> PanelTarget {
        return PanelTarget(
            code: code,
            title: title,
            approved: false,
            refills: 0,
            budget: 0.0,
            status: PanelTargetStatus.draft
        )
    }
}

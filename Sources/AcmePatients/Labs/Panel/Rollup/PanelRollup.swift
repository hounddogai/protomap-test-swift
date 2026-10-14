import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel rollup is in its life cycle.
    enum PanelRollupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a panel rollup and its current status.
    final class PanelRollup {
        var code: String
        var title: String
        var summary: String
        var source: String
        var notes: String
        var ward: String
        var reviewer: String
        var category: String
        var durationMinutes: Int
        var visible: Bool
        var status: PanelRollupStatus

        init(code: String, title: String, summary: String, source: String, notes: String, ward: String, reviewer: String, category: String, durationMinutes: Int, visible: Bool, status: PanelRollupStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.source = source
            self.notes = notes
            self.ward = ward
            self.reviewer = reviewer
            self.category = category
            self.durationMinutes = durationMinutes
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PanelRollupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PanelRollupStatus.rejected || next == PanelRollupStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PanelRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> PanelRollup {
            return PanelRollup(
                code: code,
                title: title,
                summary: summary,
                source: source,
                notes: notes,
                ward: ward,
                reviewer: reviewer,
                category: category,
                durationMinutes: durationMinutes,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a panel rollup in status proposed.
    static func newPanelRollup(_ code: String, title: String) -> PanelRollup {
        return PanelRollup(
            code: code,
            title: title,
            summary: "",
            source: "",
            notes: "",
            ward: "",
            reviewer: "",
            category: "",
            durationMinutes: 0,
            visible: false,
            status: PanelRollupStatus.proposed
        )
    }
}

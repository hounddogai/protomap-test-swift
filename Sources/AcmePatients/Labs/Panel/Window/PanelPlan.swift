import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel plan is in its life cycle.
    enum PanelPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A panel plan as the panel team keeps it.
    final class PanelPlan {
        var code: String
        var title: String
        var refills: Int
        var floorValue: Double
        var reviewer: String
        var tags: [String]
        var status: PanelPlanStatus

        init(code: String, title: String, refills: Int, floorValue: Double, reviewer: String, tags: [String], status: PanelPlanStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.floorValue = floorValue
            self.reviewer = reviewer
            self.tags = tags
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

        func canMoveTo(_ next: PanelPlanStatus) -> Bool {
            switch status {
            case .draft:
                return next == PanelPlanStatus.pending || next == PanelPlanStatus.closed
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PanelPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((Double(refills) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> PanelPlan {
            return PanelPlan(
                code: code,
                title: title,
                refills: refills,
                floorValue: floorValue,
                reviewer: reviewer,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a panel plan in status draft.
    static func newPanelPlan(_ code: String, title: String) -> PanelPlan {
        return PanelPlan(
            code: code,
            title: title,
            refills: 0,
            floorValue: 0.0,
            reviewer: "",
            tags: [],
            status: PanelPlanStatus.draft
        )
    }
}

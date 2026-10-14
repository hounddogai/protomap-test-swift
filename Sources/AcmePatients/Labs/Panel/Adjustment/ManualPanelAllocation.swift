import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual panel allocation is in its life cycle.
    enum ManualPanelAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual panel allocation as the panel team keeps it.
    final class ManualPanelAllocation {
        var code: String
        var title: String
        var threshold: Double
        var floorValue: Double
        var revision: Int
        var payer: String
        var source: String
        var status: ManualPanelAllocationStatus

        init(code: String, title: String, threshold: Double, floorValue: Double, revision: Int, payer: String, source: String, status: ManualPanelAllocationStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.floorValue = floorValue
            self.revision = revision
            self.payer = payer
            self.source = source
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

        func canMoveTo(_ next: ManualPanelAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ManualPanelAllocationStatus.resolved || next == ManualPanelAllocationStatus.archived
            case .inReview:
                return next == ManualPanelAllocationStatus.archived
            case .resolved:
                return next == ManualPanelAllocationStatus.reopened || next == ManualPanelAllocationStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ManualPanelAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual panel allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netTotal() -> Double {
            return (floorValue * threshold * 100).rounded() / 100
        }

        func copyValue() -> ManualPanelAllocation {
            return ManualPanelAllocation(
                code: code,
                title: title,
                threshold: threshold,
                floorValue: floorValue,
                revision: revision,
                payer: payer,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a manual panel allocation in status open.
    static func newManualPanelAllocation(_ code: String, title: String) -> ManualPanelAllocation {
        return ManualPanelAllocation(
            code: code,
            title: title,
            threshold: 0.0,
            floorValue: 0.0,
            revision: 0,
            payer: "",
            source: "",
            status: ManualPanelAllocationStatus.`open`
        )
    }
}

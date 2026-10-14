import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol target is in its life cycle.
    enum CareProtocolTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A care protocol target. Its code is unique within a tenant.
    final class CareProtocolTarget {
        var code: String
        var title: String
        var region: String
        var visible: Bool
        var acuity: Int
        var rate: Double
        var archived: Bool
        var procedureCode: String
        var pinned: Bool
        var maximum: Double
        var summary: String
        var status: CareProtocolTargetStatus

        init(code: String, title: String, region: String, visible: Bool, acuity: Int, rate: Double, archived: Bool, procedureCode: String, pinned: Bool, maximum: Double, summary: String, status: CareProtocolTargetStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.visible = visible
            self.acuity = acuity
            self.rate = rate
            self.archived = archived
            self.procedureCode = procedureCode
            self.pinned = pinned
            self.maximum = maximum
            self.summary = summary
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

        func canMoveTo(_ next: CareProtocolTargetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CareProtocolTargetStatus.closed
            case .active:
                return next == CareProtocolTargetStatus.closed
            case .suspended:
                return next == CareProtocolTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveTotal() -> Double {
            return ((maximum - rate) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolTarget {
            return CareProtocolTarget(
                code: code,
                title: title,
                region: region,
                visible: visible,
                acuity: acuity,
                rate: rate,
                archived: archived,
                procedureCode: procedureCode,
                pinned: pinned,
                maximum: maximum,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a care protocol target in status draft.
    static func newCareProtocolTarget(_ code: String, title: String) -> CareProtocolTarget {
        return CareProtocolTarget(
            code: code,
            title: title,
            region: "",
            visible: false,
            acuity: 0,
            rate: 0.0,
            archived: false,
            procedureCode: "",
            pinned: false,
            maximum: 0.0,
            summary: "",
            status: CareProtocolTargetStatus.draft
        )
    }
}

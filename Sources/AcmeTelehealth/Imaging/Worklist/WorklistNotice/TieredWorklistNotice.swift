import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered worklist notice is in its life cycle.
    enum TieredWorklistNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One tiered worklist notice, with what the planners need to act on it.
    final class TieredWorklistNotice {
        var code: String
        var label: String
        var active: Bool
        var name: String
        var refills: Int
        var minimum: Double
        var visible: Bool
        var status: TieredWorklistNoticeStatus

        init(code: String, label: String, active: Bool, name: String, refills: Int, minimum: Double, visible: Bool, status: TieredWorklistNoticeStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.name = name
            self.refills = refills
            self.minimum = minimum
            self.visible = visible
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

        func canMoveTo(_ next: TieredWorklistNoticeStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == TieredWorklistNoticeStatus.archived
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

        func moveTo(_ next: TieredWorklistNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered worklist notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return ((minimum - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> TieredWorklistNotice {
            return TieredWorklistNotice(
                code: code,
                label: label,
                active: active,
                name: name,
                refills: refills,
                minimum: minimum,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered worklist notice in status open.
    static func newTieredWorklistNotice(_ code: String, label: String) -> TieredWorklistNotice {
        return TieredWorklistNotice(
            code: code,
            label: label,
            active: false,
            name: "",
            refills: 0,
            minimum: 0.0,
            visible: false,
            status: TieredWorklistNoticeStatus.`open`
        )
    }
}

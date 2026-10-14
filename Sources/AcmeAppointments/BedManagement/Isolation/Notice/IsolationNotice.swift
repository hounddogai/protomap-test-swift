import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation notice is in its life cycle.
    enum IsolationNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A isolation notice. Its code is unique within a tenant.
    final class IsolationNotice {
        var code: String
        var label: String
        var endsAt: Int
        var refills: Int
        var title: String
        var floorValue: Double
        var procedureCode: String
        var status: IsolationNoticeStatus

        init(code: String, label: String, endsAt: Int, refills: Int, title: String, floorValue: Double, procedureCode: String, status: IsolationNoticeStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.refills = refills
            self.title = title
            self.floorValue = floorValue
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: IsolationNoticeStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == IsolationNoticeStatus.suspended
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

        func moveTo(_ next: IsolationNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(refills) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> IsolationNotice {
            return IsolationNotice(
                code: code,
                label: label,
                endsAt: endsAt,
                refills: refills,
                title: title,
                floorValue: floorValue,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a isolation notice in status draft.
    static func newIsolationNotice(_ code: String, label: String) -> IsolationNotice {
        return IsolationNotice(
            code: code,
            label: label,
            endsAt: 0,
            refills: 0,
            title: "",
            floorValue: 0.0,
            procedureCode: "",
            status: IsolationNoticeStatus.draft
        )
    }
}

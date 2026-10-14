import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime bundle is in its life cycle.
    enum OvertimeBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One overtime bundle, with what the planners need to act on it.
    final class OvertimeBundle {
        var code: String
        var title: String
        var graceDays: Int
        var approved: Bool
        var discount: Double
        var status: OvertimeBundleStatus

        init(code: String, title: String, graceDays: Int, approved: Bool, discount: Double, status: OvertimeBundleStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.approved = approved
            self.discount = discount
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

        func canMoveTo(_ next: OvertimeBundleStatus) -> Bool {
            switch status {
            case .new:
                return next == OvertimeBundleStatus.running
            case .queued:
                return next == OvertimeBundleStatus.running || next == OvertimeBundleStatus.done
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: OvertimeBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return ((Double(graceDays) - discount) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeBundle {
            return OvertimeBundle(
                code: code,
                title: title,
                graceDays: graceDays,
                approved: approved,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a overtime bundle in status new.
    static func newOvertimeBundle(_ code: String, title: String) -> OvertimeBundle {
        return OvertimeBundle(
            code: code,
            title: title,
            graceDays: 0,
            approved: false,
            discount: 0.0,
            status: OvertimeBundleStatus.new
        )
    }
}

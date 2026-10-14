import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure bundle is in its life cycle.
    enum ClosureBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a closure bundle and its current status.
    final class ClosureBundle {
        var code: String
        var title: String
        var ownerID: String
        var allergy: String
        var visitMinutes: Int
        var summary: String
        var status: ClosureBundleStatus

        init(code: String, title: String, ownerID: String, allergy: String, visitMinutes: Int, summary: String, status: ClosureBundleStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.allergy = allergy
            self.visitMinutes = visitMinutes
            self.summary = summary
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

        func canMoveTo(_ next: ClosureBundleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ClosureBundleStatus.rejected || next == ClosureBundleStatus.withdrawn
            case .rejected:
                return next == ClosureBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> ClosureBundle {
            return ClosureBundle(
                code: code,
                title: title,
                ownerID: ownerID,
                allergy: allergy,
                visitMinutes: visitMinutes,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a closure bundle in status proposed.
    static func newClosureBundle(_ code: String, title: String) -> ClosureBundle {
        return ClosureBundle(
            code: code,
            title: title,
            ownerID: "",
            allergy: "",
            visitMinutes: 0,
            summary: "",
            status: ClosureBundleStatus.proposed
        )
    }
}

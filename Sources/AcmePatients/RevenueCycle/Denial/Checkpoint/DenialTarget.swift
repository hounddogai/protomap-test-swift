import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial target is in its life cycle.
    enum DenialTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A denial target. Its code is unique within a tenant.
    final class DenialTarget {
        var code: String
        var title: String
        var checksum: String
        var pinned: Bool
        var refills: Int
        var currency: String
        var status: DenialTargetStatus

        init(code: String, title: String, checksum: String, pinned: Bool, refills: Int, currency: String, status: DenialTargetStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.pinned = pinned
            self.refills = refills
            self.currency = currency
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

        func canMoveTo(_ next: DenialTargetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == DenialTargetStatus.resolved || next == DenialTargetStatus.reopened
            case .resolved:
                return next == DenialTargetStatus.archived
            case .reopened:
                return next == DenialTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("denial target") \(code)"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> DenialTarget {
            return DenialTarget(
                code: code,
                title: title,
                checksum: checksum,
                pinned: pinned,
                refills: refills,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a denial target in status open.
    static func newDenialTarget(_ code: String, title: String) -> DenialTarget {
        return DenialTarget(
            code: code,
            title: title,
            checksum: "",
            pinned: false,
            refills: 0,
            currency: "",
            status: DenialTargetStatus.`open`
        )
    }
}

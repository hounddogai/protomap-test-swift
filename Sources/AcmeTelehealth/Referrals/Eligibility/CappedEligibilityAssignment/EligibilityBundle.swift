import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility bundle is in its life cycle.
    enum EligibilityBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a eligibility bundle and its current status.
    final class EligibilityBundle {
        var code: String
        var title: String
        var sequence: Int
        var priority: Int
        var cost: Double
        var ownerID: String
        var status: EligibilityBundleStatus

        init(code: String, title: String, sequence: Int, priority: Int, cost: Double, ownerID: String, status: EligibilityBundleStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.priority = priority
            self.cost = cost
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: EligibilityBundleStatus) -> Bool {
            switch status {
            case .idle:
                return next == EligibilityBundleStatus.warming
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == EligibilityBundleStatus.stopped
            case .draining:
                return next == EligibilityBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return ((cost - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityBundle {
            return EligibilityBundle(
                code: code,
                title: title,
                sequence: sequence,
                priority: priority,
                cost: cost,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a eligibility bundle in status idle.
    static func newEligibilityBundle(_ code: String, title: String) -> EligibilityBundle {
        return EligibilityBundle(
            code: code,
            title: title,
            sequence: 0,
            priority: 0,
            cost: 0.0,
            ownerID: "",
            status: EligibilityBundleStatus.idle
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim threshold is in its life cycle.
    enum ClaimThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A claim threshold as the claim team keeps it.
    final class ClaimThreshold {
        var code: String
        var title: String
        var patientRef: String
        var category: String
        var archived: Bool
        var quantity: Int
        var status: ClaimThresholdStatus

        init(code: String, title: String, patientRef: String, category: String, archived: Bool, quantity: Int, status: ClaimThresholdStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.category = category
            self.archived = archived
            self.quantity = quantity
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

        func canMoveTo(_ next: ClaimThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ClaimThresholdStatus.withdrawn
            case .rejected:
                return next == ClaimThresholdStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ClaimThreshold {
            return ClaimThreshold(
                code: code,
                title: title,
                patientRef: patientRef,
                category: category,
                archived: archived,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a claim threshold in status proposed.
    static func newClaimThreshold(_ code: String, title: String) -> ClaimThreshold {
        return ClaimThreshold(
            code: code,
            title: title,
            patientRef: "",
            category: "",
            archived: false,
            quantity: 0,
            status: ClaimThresholdStatus.proposed
        )
    }
}

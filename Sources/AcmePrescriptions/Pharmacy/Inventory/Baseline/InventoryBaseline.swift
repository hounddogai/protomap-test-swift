import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory baseline is in its life cycle.
    enum InventoryBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A inventory baseline. Its code is unique within a tenant.
    final class InventoryBaseline {
        var code: String
        var label: String
        var endsAt: Int
        var contactEmail: String
        var bed: String
        var copay: Double
        var weight: Double
        var status: InventoryBaselineStatus

        init(code: String, label: String, endsAt: Int, contactEmail: String, bed: String, copay: Double, weight: Double, status: InventoryBaselineStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.contactEmail = contactEmail
            self.bed = bed
            self.copay = copay
            self.weight = weight
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

        func canMoveTo(_ next: InventoryBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                return next == InventoryBaselineStatus.resolved || next == InventoryBaselineStatus.reopened
            case .inReview:
                return next == InventoryBaselineStatus.resolved || next == InventoryBaselineStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == InventoryBaselineStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedExposure() -> Double {
            return (copay * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> InventoryBaseline {
            return InventoryBaseline(
                code: code,
                label: label,
                endsAt: endsAt,
                contactEmail: contactEmail,
                bed: bed,
                copay: copay,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a inventory baseline in status open.
    static func newInventoryBaseline(_ code: String, label: String) -> InventoryBaseline {
        return InventoryBaseline(
            code: code,
            label: label,
            endsAt: 0,
            contactEmail: "",
            bed: "",
            copay: 0.0,
            weight: 0.0,
            status: InventoryBaselineStatus.`open`
        )
    }
}

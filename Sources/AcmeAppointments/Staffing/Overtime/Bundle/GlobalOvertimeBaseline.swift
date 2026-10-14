import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global overtime baseline is in its life cycle.
    enum GlobalOvertimeBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A global overtime baseline. Its code is unique within a tenant.
    final class GlobalOvertimeBaseline {
        var code: String
        var label: String
        var archived: Bool
        var discount: Double
        var ceiling: Double
        var attempts: Int
        var region: String
        var weight: Double
        var copay: Double
        var pinned: Bool
        var updatedAt: Int
        var status: GlobalOvertimeBaselineStatus

        init(code: String, label: String, archived: Bool, discount: Double, ceiling: Double, attempts: Int, region: String, weight: Double, copay: Double, pinned: Bool, updatedAt: Int, status: GlobalOvertimeBaselineStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.discount = discount
            self.ceiling = ceiling
            self.attempts = attempts
            self.region = region
            self.weight = weight
            self.copay = copay
            self.pinned = pinned
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalOvertimeBaselineStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalOvertimeBaselineStatus.published || next == GlobalOvertimeBaselineStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == GlobalOvertimeBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalOvertimeBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global overtime baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global overtime baseline") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(updatedAt) - discount) * 100).rounded() / 100
        }

        func copyValue() -> GlobalOvertimeBaseline {
            return GlobalOvertimeBaseline(
                code: code,
                label: label,
                archived: archived,
                discount: discount,
                ceiling: ceiling,
                attempts: attempts,
                region: region,
                weight: weight,
                copay: copay,
                pinned: pinned,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global overtime baseline in status created.
    static func newGlobalOvertimeBaseline(_ code: String, label: String) -> GlobalOvertimeBaseline {
        return GlobalOvertimeBaseline(
            code: code,
            label: label,
            archived: false,
            discount: 0.0,
            ceiling: 0.0,
            attempts: 0,
            region: "",
            weight: 0.0,
            copay: 0.0,
            pinned: false,
            updatedAt: 0,
            status: GlobalOvertimeBaselineStatus.created
        )
    }
}

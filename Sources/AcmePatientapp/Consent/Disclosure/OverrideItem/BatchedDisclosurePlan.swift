import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched disclosure plan is in its life cycle.
    enum BatchedDisclosurePlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched disclosure plan. Its code is unique within a tenant.
    final class BatchedDisclosurePlan {
        var code: String
        var title: String
        var phone: String
        var copay: Double
        var updatedAt: Int
        var ward: String
        var status: BatchedDisclosurePlanStatus

        init(code: String, title: String, phone: String, copay: Double, updatedAt: Int, ward: String, status: BatchedDisclosurePlanStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.copay = copay
            self.updatedAt = updatedAt
            self.ward = ward
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

        func canMoveTo(_ next: BatchedDisclosurePlanStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: BatchedDisclosurePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched disclosure plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedVolume() -> Double {
            return ((Double(updatedAt) - copay) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDisclosurePlan {
            return BatchedDisclosurePlan(
                code: code,
                title: title,
                phone: phone,
                copay: copay,
                updatedAt: updatedAt,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a batched disclosure plan in status proposed.
    static func newBatchedDisclosurePlan(_ code: String, title: String) -> BatchedDisclosurePlan {
        return BatchedDisclosurePlan(
            code: code,
            title: title,
            phone: "",
            copay: 0.0,
            updatedAt: 0,
            ward: "",
            status: BatchedDisclosurePlanStatus.proposed
        )
    }
}

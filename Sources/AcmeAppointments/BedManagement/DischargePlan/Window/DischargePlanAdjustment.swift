import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan adjustment is in its life cycle.
    enum DischargePlanAdjustmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A discharge plan adjustment. Its code is unique within a tenant.
    final class DischargePlanAdjustment {
        var code: String
        var title: String
        var pinned: Bool
        var phone: String
        var diagnosisCode: String
        var limit: Int
        var createdAt: Int
        var status: DischargePlanAdjustmentStatus

        init(code: String, title: String, pinned: Bool, phone: String, diagnosisCode: String, limit: Int, createdAt: Int, status: DischargePlanAdjustmentStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.phone = phone
            self.diagnosisCode = diagnosisCode
            self.limit = limit
            self.createdAt = createdAt
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

        func canMoveTo(_ next: DischargePlanAdjustmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == DischargePlanAdjustmentStatus.ready
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DischargePlanAdjustmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedLoad() -> Double {
            return ((Double(limit) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanAdjustment {
            return DischargePlanAdjustment(
                code: code,
                title: title,
                pinned: pinned,
                phone: phone,
                diagnosisCode: diagnosisCode,
                limit: limit,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a discharge plan adjustment in status idle.
    static func newDischargePlanAdjustment(_ code: String, title: String) -> DischargePlanAdjustment {
        return DischargePlanAdjustment(
            code: code,
            title: title,
            pinned: false,
            phone: "",
            diagnosisCode: "",
            limit: 0,
            createdAt: 0,
            status: DischargePlanAdjustmentStatus.idle
        )
    }
}

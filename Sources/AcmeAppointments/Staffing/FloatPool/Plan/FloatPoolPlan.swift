import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool plan is in its life cycle.
    enum FloatPoolPlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A float pool plan as the float pool team keeps it.
    final class FloatPoolPlan {
        var code: String
        var title: String
        var batchSize: Int
        var pinned: Bool
        var endsAt: Int
        var archived: Bool
        var region: String
        var visible: Bool
        var payer: String
        var status: FloatPoolPlanStatus

        init(code: String, title: String, batchSize: Int, pinned: Bool, endsAt: Int, archived: Bool, region: String, visible: Bool, payer: String, status: FloatPoolPlanStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.pinned = pinned
            self.endsAt = endsAt
            self.archived = archived
            self.region = region
            self.visible = visible
            self.payer = payer
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

        func canMoveTo(_ next: FloatPoolPlanStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == FloatPoolPlanStatus.rejected || next == FloatPoolPlanStatus.withdrawn
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

        func moveTo(_ next: FloatPoolPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return ((Double(endsAt) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolPlan {
            return FloatPoolPlan(
                code: code,
                title: title,
                batchSize: batchSize,
                pinned: pinned,
                endsAt: endsAt,
                archived: archived,
                region: region,
                visible: visible,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a float pool plan in status proposed.
    static func newFloatPoolPlan(_ code: String, title: String) -> FloatPoolPlan {
        return FloatPoolPlan(
            code: code,
            title: title,
            batchSize: 0,
            pinned: false,
            endsAt: 0,
            archived: false,
            region: "",
            visible: false,
            payer: "",
            status: FloatPoolPlanStatus.proposed
        )
    }
}

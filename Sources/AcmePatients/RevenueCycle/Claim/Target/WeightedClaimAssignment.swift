import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted claim assignment is in its life cycle.
    enum WeightedClaimAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted claim assignment as the claim team keeps it.
    final class WeightedClaimAssignment {
        var code: String
        var title: String
        var updatedAt: Int
        var discount: Double
        var windowDays: Int
        var ratio: Double
        var batchSize: Int
        var ward: String
        var status: WeightedClaimAssignmentStatus

        init(code: String, title: String, updatedAt: Int, discount: Double, windowDays: Int, ratio: Double, batchSize: Int, ward: String, status: WeightedClaimAssignmentStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.discount = discount
            self.windowDays = windowDays
            self.ratio = ratio
            self.batchSize = batchSize
            self.ward = ward
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedClaimAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedClaimAssignmentStatus.granted || next == WeightedClaimAssignmentStatus.expired
            case .granted:
                return next == WeightedClaimAssignmentStatus.revoked || next == WeightedClaimAssignmentStatus.expired
            case .revoked:
                return next == WeightedClaimAssignmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedClaimAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted claim assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted claim assignment") \(code)"
        }

        func adjustedValue() -> Double {
            return (Double(batchSize) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> WeightedClaimAssignment {
            return WeightedClaimAssignment(
                code: code,
                title: title,
                updatedAt: updatedAt,
                discount: discount,
                windowDays: windowDays,
                ratio: ratio,
                batchSize: batchSize,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a weighted claim assignment in status requested.
    static func newWeightedClaimAssignment(_ code: String, title: String) -> WeightedClaimAssignment {
        return WeightedClaimAssignment(
            code: code,
            title: title,
            updatedAt: 0,
            discount: 0.0,
            windowDays: 0,
            ratio: 0.0,
            batchSize: 0,
            ward: "",
            status: WeightedClaimAssignmentStatus.requested
        )
    }
}

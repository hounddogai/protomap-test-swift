import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual claim estimate is in its life cycle.
    enum ManualClaimEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual claim estimate. Its code is unique within a tenant.
    final class ManualClaimEstimate {
        var code: String
        var name: String
        var reviewer: String
        var endsAt: Int
        var maximum: Double
        var approved: Bool
        var capacity: Int
        var status: ManualClaimEstimateStatus

        init(code: String, name: String, reviewer: String, endsAt: Int, maximum: Double, approved: Bool, capacity: Int, status: ManualClaimEstimateStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.maximum = maximum
            self.approved = approved
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualClaimEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == ManualClaimEstimateStatus.done
            case .queued:
                return next == ManualClaimEstimateStatus.running || next == ManualClaimEstimateStatus.done
            case .running:
                return next == ManualClaimEstimateStatus.failed
            case .done:
                return next == ManualClaimEstimateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualClaimEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual claim estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual claim estimate") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(endsAt) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> ManualClaimEstimate {
            return ManualClaimEstimate(
                code: code,
                name: name,
                reviewer: reviewer,
                endsAt: endsAt,
                maximum: maximum,
                approved: approved,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual claim estimate in status new.
    static func newManualClaimEstimate(_ code: String, name: String) -> ManualClaimEstimate {
        return ManualClaimEstimate(
            code: code,
            name: name,
            reviewer: "",
            endsAt: 0,
            maximum: 0.0,
            approved: false,
            capacity: 0,
            status: ManualClaimEstimateStatus.new
        )
    }
}

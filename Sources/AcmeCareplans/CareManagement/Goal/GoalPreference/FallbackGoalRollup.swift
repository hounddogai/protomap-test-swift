import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback goal rollup is in its life cycle.
    enum FallbackGoalRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One fallback goal rollup, with what the planners need to act on it.
    final class FallbackGoalRollup {
        var code: String
        var name: String
        var externalRef: String
        var phone: String
        var channel: String
        var copay: Double
        var visible: Bool
        var margin: Double
        var approved: Bool
        var expiresAt: Int
        var createdAt: Int
        var status: FallbackGoalRollupStatus

        init(code: String, name: String, externalRef: String, phone: String, channel: String, copay: Double, visible: Bool, margin: Double, approved: Bool, expiresAt: Int, createdAt: Int, status: FallbackGoalRollupStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.phone = phone
            self.channel = channel
            self.copay = copay
            self.visible = visible
            self.margin = margin
            self.approved = approved
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: FallbackGoalRollupStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackGoalRollupStatus.ready || next == FallbackGoalRollupStatus.stopped
            case .warming:
                return next == FallbackGoalRollupStatus.ready || next == FallbackGoalRollupStatus.draining
            case .ready:
                return next == FallbackGoalRollupStatus.stopped
            case .draining:
                return next == FallbackGoalRollupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackGoalRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback goal rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedVolume() -> Double {
            return (margin * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> FallbackGoalRollup {
            return FallbackGoalRollup(
                code: code,
                name: name,
                externalRef: externalRef,
                phone: phone,
                channel: channel,
                copay: copay,
                visible: visible,
                margin: margin,
                approved: approved,
                expiresAt: expiresAt,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a fallback goal rollup in status idle.
    static func newFallbackGoalRollup(_ code: String, name: String) -> FallbackGoalRollup {
        return FallbackGoalRollup(
            code: code,
            name: name,
            externalRef: "",
            phone: "",
            channel: "",
            copay: 0.0,
            visible: false,
            margin: 0.0,
            approved: false,
            expiresAt: 0,
            createdAt: 0,
            status: FallbackGoalRollupStatus.idle
        )
    }
}

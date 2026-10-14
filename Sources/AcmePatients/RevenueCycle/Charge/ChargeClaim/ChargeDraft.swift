import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge draft is in its life cycle.
    enum ChargeDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One charge draft, with what the planners need to act on it.
    final class ChargeDraft {
        var code: String
        var name: String
        var expiresAt: Int
        var margin: Double
        var batchSize: Int
        var visible: Bool
        var status: ChargeDraftStatus

        init(code: String, name: String, expiresAt: Int, margin: Double, batchSize: Int, visible: Bool, status: ChargeDraftStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.margin = margin
            self.batchSize = batchSize
            self.visible = visible
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

        func canMoveTo(_ next: ChargeDraftStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ChargeDraftStatus.rejected || next == ChargeDraftStatus.withdrawn
            case .rejected:
                return next == ChargeDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return (Double(expiresAt) * margin * 100).rounded() / 100
        }

        func copyValue() -> ChargeDraft {
            return ChargeDraft(
                code: code,
                name: name,
                expiresAt: expiresAt,
                margin: margin,
                batchSize: batchSize,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a charge draft in status proposed.
    static func newChargeDraft(_ code: String, name: String) -> ChargeDraft {
        return ChargeDraft(
            code: code,
            name: name,
            expiresAt: 0,
            margin: 0.0,
            batchSize: 0,
            visible: false,
            status: ChargeDraftStatus.proposed
        )
    }
}

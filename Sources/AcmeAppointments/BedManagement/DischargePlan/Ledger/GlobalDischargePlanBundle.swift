import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global discharge plan bundle is in its life cycle.
    enum GlobalDischargePlanBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global discharge plan bundle, with what the planners need to act on it.
    final class GlobalDischargePlanBundle {
        var code: String
        var name: String
        var startsAt: Int
        var approved: Bool
        var ratio: Double
        var amount: Double
        var durationMinutes: Int
        var batchSize: Int
        var status: GlobalDischargePlanBundleStatus

        init(code: String, name: String, startsAt: Int, approved: Bool, ratio: Double, amount: Double, durationMinutes: Int, batchSize: Int, status: GlobalDischargePlanBundleStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.approved = approved
            self.ratio = ratio
            self.amount = amount
            self.durationMinutes = durationMinutes
            self.batchSize = batchSize
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

        func canMoveTo(_ next: GlobalDischargePlanBundleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == GlobalDischargePlanBundleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalDischargePlanBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global discharge plan bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalDischargePlanBundle {
            return GlobalDischargePlanBundle(
                code: code,
                name: name,
                startsAt: startsAt,
                approved: approved,
                ratio: ratio,
                amount: amount,
                durationMinutes: durationMinutes,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global discharge plan bundle in status requested.
    static func newGlobalDischargePlanBundle(_ code: String, name: String) -> GlobalDischargePlanBundle {
        return GlobalDischargePlanBundle(
            code: code,
            name: name,
            startsAt: 0,
            approved: false,
            ratio: 0.0,
            amount: 0.0,
            durationMinutes: 0,
            batchSize: 0,
            status: GlobalDischargePlanBundleStatus.requested
        )
    }
}

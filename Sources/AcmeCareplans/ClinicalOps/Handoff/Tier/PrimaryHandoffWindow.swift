import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary handoff window is in its life cycle.
    enum PrimaryHandoffWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A primary handoff window as the handoff team keeps it.
    final class PrimaryHandoffWindow {
        var code: String
        var title: String
        var rate: Double
        var createdAt: Int
        var timezone: String
        var bed: String
        var region: String
        var status: PrimaryHandoffWindowStatus

        init(code: String, title: String, rate: Double, createdAt: Int, timezone: String, bed: String, region: String, status: PrimaryHandoffWindowStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.createdAt = createdAt
            self.timezone = timezone
            self.bed = bed
            self.region = region
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

        func canMoveTo(_ next: PrimaryHandoffWindowStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PrimaryHandoffWindowStatus.revoked || next == PrimaryHandoffWindowStatus.expired
            case .revoked:
                return next == PrimaryHandoffWindowStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryHandoffWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary handoff window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return (rate * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryHandoffWindow {
            return PrimaryHandoffWindow(
                code: code,
                title: title,
                rate: rate,
                createdAt: createdAt,
                timezone: timezone,
                bed: bed,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a primary handoff window in status requested.
    static func newPrimaryHandoffWindow(_ code: String, title: String) -> PrimaryHandoffWindow {
        return PrimaryHandoffWindow(
            code: code,
            title: title,
            rate: 0.0,
            createdAt: 0,
            timezone: "",
            bed: "",
            region: "",
            status: PrimaryHandoffWindowStatus.requested
        )
    }
}

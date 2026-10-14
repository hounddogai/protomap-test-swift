import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board slot is in its life cycle.
    enum BedBoardSlotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A bed board slot as the bed board team keeps it.
    final class BedBoardSlot {
        var code: String
        var name: String
        var bed: String
        var version: Int
        var region: String
        var pinned: Bool
        var country: String
        var expiresAt: Int
        var ceiling: Double
        var status: BedBoardSlotStatus

        init(code: String, name: String, bed: String, version: Int, region: String, pinned: Bool, country: String, expiresAt: Int, ceiling: Double, status: BedBoardSlotStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.version = version
            self.region = region
            self.pinned = pinned
            self.country = country
            self.expiresAt = expiresAt
            self.ceiling = ceiling
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

        func canMoveTo(_ next: BedBoardSlotStatus) -> Bool {
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
                return next == BedBoardSlotStatus.revoked || next == BedBoardSlotStatus.expired
            case .revoked:
                return next == BedBoardSlotStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return ((ceiling - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardSlot {
            return BedBoardSlot(
                code: code,
                name: name,
                bed: bed,
                version: version,
                region: region,
                pinned: pinned,
                country: country,
                expiresAt: expiresAt,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a bed board slot in status requested.
    static func newBedBoardSlot(_ code: String, name: String) -> BedBoardSlot {
        return BedBoardSlot(
            code: code,
            name: name,
            bed: "",
            version: 0,
            region: "",
            pinned: false,
            country: "",
            expiresAt: 0,
            ceiling: 0.0,
            status: BedBoardSlotStatus.requested
        )
    }
}

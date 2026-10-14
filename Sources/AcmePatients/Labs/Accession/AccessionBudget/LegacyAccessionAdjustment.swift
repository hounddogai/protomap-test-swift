import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy accession adjustment is in its life cycle.
    enum LegacyAccessionAdjustmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One legacy accession adjustment, with what the planners need to act on it.
    final class LegacyAccessionAdjustment {
        var code: String
        var name: String
        var rate: Double
        var sequence: Int
        var floorValue: Double
        var status: LegacyAccessionAdjustmentStatus

        init(code: String, name: String, rate: Double, sequence: Int, floorValue: Double, status: LegacyAccessionAdjustmentStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.sequence = sequence
            self.floorValue = floorValue
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

        func canMoveTo(_ next: LegacyAccessionAdjustmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == LegacyAccessionAdjustmentStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: LegacyAccessionAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy accession adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedExposure() -> Double {
            return ((floorValue + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAccessionAdjustment {
            return LegacyAccessionAdjustment(
                code: code,
                name: name,
                rate: rate,
                sequence: sequence,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy accession adjustment in status requested.
    static func newLegacyAccessionAdjustment(_ code: String, name: String) -> LegacyAccessionAdjustment {
        return LegacyAccessionAdjustment(
            code: code,
            name: name,
            rate: 0.0,
            sequence: 0,
            floorValue: 0.0,
            status: LegacyAccessionAdjustmentStatus.requested
        )
    }
}

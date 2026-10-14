import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default bed board rollup is in its life cycle.
    enum DefaultBedBoardRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a default bed board rollup and its current status.
    final class DefaultBedBoardRollup {
        var code: String
        var label: String
        var segment: String
        var phone: String
        var clinicianID: String
        var cost: Double
        var version: Int
        var endsAt: Int
        var externalRef: String
        var status: DefaultBedBoardRollupStatus

        init(code: String, label: String, segment: String, phone: String, clinicianID: String, cost: Double, version: Int, endsAt: Int, externalRef: String, status: DefaultBedBoardRollupStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.phone = phone
            self.clinicianID = clinicianID
            self.cost = cost
            self.version = version
            self.endsAt = endsAt
            self.externalRef = externalRef
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

        func canMoveTo(_ next: DefaultBedBoardRollupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultBedBoardRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default bed board rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("default bed board rollup") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(endsAt) * cost * 100).rounded() / 100
        }

        func copyValue() -> DefaultBedBoardRollup {
            return DefaultBedBoardRollup(
                code: code,
                label: label,
                segment: segment,
                phone: phone,
                clinicianID: clinicianID,
                cost: cost,
                version: version,
                endsAt: endsAt,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a default bed board rollup in status requested.
    static func newDefaultBedBoardRollup(_ code: String, label: String) -> DefaultBedBoardRollup {
        return DefaultBedBoardRollup(
            code: code,
            label: label,
            segment: "",
            phone: "",
            clinicianID: "",
            cost: 0.0,
            version: 0,
            endsAt: 0,
            externalRef: "",
            status: DefaultBedBoardRollupStatus.requested
        )
    }
}

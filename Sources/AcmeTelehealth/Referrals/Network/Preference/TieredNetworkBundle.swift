import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered network bundle is in its life cycle.
    enum TieredNetworkBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a tiered network bundle and its current status.
    final class TieredNetworkBundle {
        var code: String
        var label: String
        var ownerID: String
        var allergy: String
        var source: String
        var checksum: String
        var sequence: Int
        var weight: Double
        var patientRef: String
        var amount: Double
        var status: TieredNetworkBundleStatus

        init(code: String, label: String, ownerID: String, allergy: String, source: String, checksum: String, sequence: Int, weight: Double, patientRef: String, amount: Double, status: TieredNetworkBundleStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.allergy = allergy
            self.source = source
            self.checksum = checksum
            self.sequence = sequence
            self.weight = weight
            self.patientRef = patientRef
            self.amount = amount
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

        func canMoveTo(_ next: TieredNetworkBundleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredNetworkBundleStatus.rejected || next == TieredNetworkBundleStatus.withdrawn
            case .approved:
                return next == TieredNetworkBundleStatus.withdrawn
            case .rejected:
                return next == TieredNetworkBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredNetworkBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered network bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return (amount * weight * 100).rounded() / 100
        }

        func copyValue() -> TieredNetworkBundle {
            return TieredNetworkBundle(
                code: code,
                label: label,
                ownerID: ownerID,
                allergy: allergy,
                source: source,
                checksum: checksum,
                sequence: sequence,
                weight: weight,
                patientRef: patientRef,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered network bundle in status proposed.
    static func newTieredNetworkBundle(_ code: String, label: String) -> TieredNetworkBundle {
        return TieredNetworkBundle(
            code: code,
            label: label,
            ownerID: "",
            allergy: "",
            source: "",
            checksum: "",
            sequence: 0,
            weight: 0.0,
            patientRef: "",
            amount: 0.0,
            status: TieredNetworkBundleStatus.proposed
        )
    }
}

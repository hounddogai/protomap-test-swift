import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual care protocol mapping is in its life cycle.
    enum ManualCareProtocolMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual care protocol mapping as the care protocol team keeps it.
    final class ManualCareProtocolMapping {
        var code: String
        var name: String
        var endsAt: Int
        var reviewer: String
        var unit: String
        var cost: Double
        var checksum: String
        var payer: String
        var source: String
        var status: ManualCareProtocolMappingStatus

        init(code: String, name: String, endsAt: Int, reviewer: String, unit: String, cost: Double, checksum: String, payer: String, source: String, status: ManualCareProtocolMappingStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.unit = unit
            self.cost = cost
            self.checksum = checksum
            self.payer = payer
            self.source = source
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

        func canMoveTo(_ next: ManualCareProtocolMappingStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ManualCareProtocolMappingStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCareProtocolMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care protocol mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedValue() -> Double {
            return (Double(endsAt) * cost * 100).rounded() / 100
        }

        func copyValue() -> ManualCareProtocolMapping {
            return ManualCareProtocolMapping(
                code: code,
                name: name,
                endsAt: endsAt,
                reviewer: reviewer,
                unit: unit,
                cost: cost,
                checksum: checksum,
                payer: payer,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a manual care protocol mapping in status proposed.
    static func newManualCareProtocolMapping(_ code: String, name: String) -> ManualCareProtocolMapping {
        return ManualCareProtocolMapping(
            code: code,
            name: name,
            endsAt: 0,
            reviewer: "",
            unit: "",
            cost: 0.0,
            checksum: "",
            payer: "",
            source: "",
            status: ManualCareProtocolMappingStatus.proposed
        )
    }
}

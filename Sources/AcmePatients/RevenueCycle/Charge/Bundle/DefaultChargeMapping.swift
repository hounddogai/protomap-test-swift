import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default charge mapping is in its life cycle.
    enum DefaultChargeMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default charge mapping. Its code is unique within a tenant.
    final class DefaultChargeMapping {
        var code: String
        var label: String
        var acuity: Int
        var maximum: Double
        var ownerID: String
        var ceiling: Double
        var clinicianID: String
        var encounterID: String
        var version: Int
        var endsAt: Int
        var status: DefaultChargeMappingStatus

        init(code: String, label: String, acuity: Int, maximum: Double, ownerID: String, ceiling: Double, clinicianID: String, encounterID: String, version: Int, endsAt: Int, status: DefaultChargeMappingStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.maximum = maximum
            self.ownerID = ownerID
            self.ceiling = ceiling
            self.clinicianID = clinicianID
            self.encounterID = encounterID
            self.version = version
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultChargeMappingStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == DefaultChargeMappingStatus.inProgress || next == DefaultChargeMappingStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == DefaultChargeMappingStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultChargeMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default charge mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((ceiling - maximum) * 100).rounded() / 100
        }

        func copyValue() -> DefaultChargeMapping {
            return DefaultChargeMapping(
                code: code,
                label: label,
                acuity: acuity,
                maximum: maximum,
                ownerID: ownerID,
                ceiling: ceiling,
                clinicianID: clinicianID,
                encounterID: encounterID,
                version: version,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default charge mapping in status planned.
    static func newDefaultChargeMapping(_ code: String, label: String) -> DefaultChargeMapping {
        return DefaultChargeMapping(
            code: code,
            label: label,
            acuity: 0,
            maximum: 0.0,
            ownerID: "",
            ceiling: 0.0,
            clinicianID: "",
            encounterID: "",
            version: 0,
            endsAt: 0,
            status: DefaultChargeMappingStatus.planned
        )
    }
}

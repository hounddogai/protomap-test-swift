import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled claim tier is in its life cycle.
    enum ScheduledClaimTierStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled claim tier as the claim team keeps it.
    final class ScheduledClaimTier {
        var code: String
        var name: String
        var visible: Bool
        var ward: String
        var diagnosisCode: String
        var ownerID: String
        var source: String
        var threshold: Double
        var status: ScheduledClaimTierStatus

        init(code: String, name: String, visible: Bool, ward: String, diagnosisCode: String, ownerID: String, source: String, threshold: Double, status: ScheduledClaimTierStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.ownerID = ownerID
            self.source = source
            self.threshold = threshold
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

        func canMoveTo(_ next: ScheduledClaimTierStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ScheduledClaimTierStatus.rejected || next == ScheduledClaimTierStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ScheduledClaimTierStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledClaimTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled claim tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> ScheduledClaimTier {
            return ScheduledClaimTier(
                code: code,
                name: name,
                visible: visible,
                ward: ward,
                diagnosisCode: diagnosisCode,
                ownerID: ownerID,
                source: source,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled claim tier in status proposed.
    static func newScheduledClaimTier(_ code: String, name: String) -> ScheduledClaimTier {
        return ScheduledClaimTier(
            code: code,
            name: name,
            visible: false,
            ward: "",
            diagnosisCode: "",
            ownerID: "",
            source: "",
            threshold: 0.0,
            status: ScheduledClaimTierStatus.proposed
        )
    }
}

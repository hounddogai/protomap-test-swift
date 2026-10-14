import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy consent form request is in its life cycle.
    enum LegacyConsentFormRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy consent form request as the consent form team keeps it.
    final class LegacyConsentFormRequest {
        var code: String
        var label: String
        var sequence: Int
        var segment: String
        var region: String
        var floorValue: Double
        var createdAt: Int
        var status: LegacyConsentFormRequestStatus

        init(code: String, label: String, sequence: Int, segment: String, region: String, floorValue: Double, createdAt: Int, status: LegacyConsentFormRequestStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.segment = segment
            self.region = region
            self.floorValue = floorValue
            self.createdAt = createdAt
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

        func canMoveTo(_ next: LegacyConsentFormRequestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == LegacyConsentFormRequestStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LegacyConsentFormRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy consent form request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveExposure() -> Double {
            return ((Double(sequence) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyConsentFormRequest {
            return LegacyConsentFormRequest(
                code: code,
                label: label,
                sequence: sequence,
                segment: segment,
                region: region,
                floorValue: floorValue,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy consent form request in status proposed.
    static func newLegacyConsentFormRequest(_ code: String, label: String) -> LegacyConsentFormRequest {
        return LegacyConsentFormRequest(
            code: code,
            label: label,
            sequence: 0,
            segment: "",
            region: "",
            floorValue: 0.0,
            createdAt: 0,
            status: LegacyConsentFormRequestStatus.proposed
        )
    }
}

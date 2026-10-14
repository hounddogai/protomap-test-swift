import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default charge request is in its life cycle.
    enum DefaultChargeRequestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default charge request. Its code is unique within a tenant.
    final class DefaultChargeRequest {
        var code: String
        var name: String
        var phone: String
        var ceiling: Double
        var country: String
        var reviewer: String
        var dosageMg: Double
        var encounterID: String
        var minimum: Double
        var payer: String
        var label: String
        var status: DefaultChargeRequestStatus

        init(code: String, name: String, phone: String, ceiling: Double, country: String, reviewer: String, dosageMg: Double, encounterID: String, minimum: Double, payer: String, label: String, status: DefaultChargeRequestStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.ceiling = ceiling
            self.country = country
            self.reviewer = reviewer
            self.dosageMg = dosageMg
            self.encounterID = encounterID
            self.minimum = minimum
            self.payer = payer
            self.label = label
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

        func canMoveTo(_ next: DefaultChargeRequestStatus) -> Bool {
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
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: DefaultChargeRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default charge request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return (ceiling * minimum * 100).rounded() / 100
        }

        func copyValue() -> DefaultChargeRequest {
            return DefaultChargeRequest(
                code: code,
                name: name,
                phone: phone,
                ceiling: ceiling,
                country: country,
                reviewer: reviewer,
                dosageMg: dosageMg,
                encounterID: encounterID,
                minimum: minimum,
                payer: payer,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default charge request in status requested.
    static func newDefaultChargeRequest(_ code: String, name: String) -> DefaultChargeRequest {
        return DefaultChargeRequest(
            code: code,
            name: name,
            phone: "",
            ceiling: 0.0,
            country: "",
            reviewer: "",
            dosageMg: 0.0,
            encounterID: "",
            minimum: 0.0,
            payer: "",
            label: "",
            status: DefaultChargeRequestStatus.requested
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a seasonal transfer policy is in its life cycle.
    enum SeasonalTransferPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a seasonal transfer policy and its current status.
    final class SeasonalTransferPolicy {
        var code: String
        var name: String
        var unit: String
        var refills: Int
        var createdAt: Int
        var acuity: Int
        var title: String
        var threshold: Double
        var contactEmail: String
        var patientRef: String
        var locale: String
        var status: SeasonalTransferPolicyStatus

        init(code: String, name: String, unit: String, refills: Int, createdAt: Int, acuity: Int, title: String, threshold: Double, contactEmail: String, patientRef: String, locale: String, status: SeasonalTransferPolicyStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.refills = refills
            self.createdAt = createdAt
            self.acuity = acuity
            self.title = title
            self.threshold = threshold
            self.contactEmail = contactEmail
            self.patientRef = patientRef
            self.locale = locale
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

        func canMoveTo(_ next: SeasonalTransferPolicyStatus) -> Bool {
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
                return next == SeasonalTransferPolicyStatus.expired
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

        func moveTo(_ next: SeasonalTransferPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal transfer policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal transfer policy") \(code)"
        }

        func projectedExposure() -> Double {
            return (threshold * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalTransferPolicy {
            return SeasonalTransferPolicy(
                code: code,
                name: name,
                unit: unit,
                refills: refills,
                createdAt: createdAt,
                acuity: acuity,
                title: title,
                threshold: threshold,
                contactEmail: contactEmail,
                patientRef: patientRef,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a seasonal transfer policy in status requested.
    static func newSeasonalTransferPolicy(_ code: String, name: String) -> SeasonalTransferPolicy {
        return SeasonalTransferPolicy(
            code: code,
            name: name,
            unit: "",
            refills: 0,
            createdAt: 0,
            acuity: 0,
            title: "",
            threshold: 0.0,
            contactEmail: "",
            patientRef: "",
            locale: "",
            status: SeasonalTransferPolicyStatus.requested
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped consent form preference is in its life cycle.
    enum CappedConsentFormPreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped consent form preference. Its code is unique within a tenant.
    final class CappedConsentFormPreference {
        var code: String
        var name: String
        var endsAt: Int
        var channel: String
        var diagnosisCode: String
        var copay: Double
        var facility: String
        var ward: String
        var quantity: Int
        var region: String
        var status: CappedConsentFormPreferenceStatus

        init(code: String, name: String, endsAt: Int, channel: String, diagnosisCode: String, copay: Double, facility: String, ward: String, quantity: Int, region: String, status: CappedConsentFormPreferenceStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.channel = channel
            self.diagnosisCode = diagnosisCode
            self.copay = copay
            self.facility = facility
            self.ward = ward
            self.quantity = quantity
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedConsentFormPreferenceStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedConsentFormPreferenceStatus.retired
            case .validated:
                return next == CappedConsentFormPreferenceStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CappedConsentFormPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped consent form preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveExposure() -> Double {
            return ((Double(endsAt) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedConsentFormPreference {
            return CappedConsentFormPreference(
                code: code,
                name: name,
                endsAt: endsAt,
                channel: channel,
                diagnosisCode: diagnosisCode,
                copay: copay,
                facility: facility,
                ward: ward,
                quantity: quantity,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped consent form preference in status created.
    static func newCappedConsentFormPreference(_ code: String, name: String) -> CappedConsentFormPreference {
        return CappedConsentFormPreference(
            code: code,
            name: name,
            endsAt: 0,
            channel: "",
            diagnosisCode: "",
            copay: 0.0,
            facility: "",
            ward: "",
            quantity: 0,
            region: "",
            status: CappedConsentFormPreferenceStatus.created
        )
    }
}

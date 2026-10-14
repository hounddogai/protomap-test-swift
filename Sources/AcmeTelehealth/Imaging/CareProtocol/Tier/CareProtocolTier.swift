import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol tier is in its life cycle.
    enum CareProtocolTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A care protocol tier. Its code is unique within a tenant.
    final class CareProtocolTier {
        var code: String
        var title: String
        var patientRef: String
        var amount: Double
        var name: String
        var country: String
        var label: String
        var payer: String
        var ward: String
        var diagnosisCode: String
        var durationMinutes: Int
        var status: CareProtocolTierStatus

        init(code: String, title: String, patientRef: String, amount: Double, name: String, country: String, label: String, payer: String, ward: String, diagnosisCode: String, durationMinutes: Int, status: CareProtocolTierStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.amount = amount
            self.name = name
            self.country = country
            self.label = label
            self.payer = payer
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: CareProtocolTierStatus) -> Bool {
            switch status {
            case .planned:
                return next == CareProtocolTierStatus.scheduled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CareProtocolTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedVolume() -> Double {
            return ((Double(durationMinutes) - amount) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolTier {
            return CareProtocolTier(
                code: code,
                title: title,
                patientRef: patientRef,
                amount: amount,
                name: name,
                country: country,
                label: label,
                payer: payer,
                ward: ward,
                diagnosisCode: diagnosisCode,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a care protocol tier in status planned.
    static func newCareProtocolTier(_ code: String, title: String) -> CareProtocolTier {
        return CareProtocolTier(
            code: code,
            title: title,
            patientRef: "",
            amount: 0.0,
            name: "",
            country: "",
            label: "",
            payer: "",
            ward: "",
            diagnosisCode: "",
            durationMinutes: 0,
            status: CareProtocolTierStatus.planned
        )
    }
}

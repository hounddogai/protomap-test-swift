import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal order set agreement is in its life cycle.
    enum SeasonalOrderSetAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a seasonal order set agreement and its current status.
    final class SeasonalOrderSetAgreement {
        var code: String
        var label: String
        var sequence: Int
        var active: Bool
        var country: String
        var dosageMg: Double
        var clinicianID: String
        var diagnosisCode: String
        var rate: Double
        var status: SeasonalOrderSetAgreementStatus

        init(code: String, label: String, sequence: Int, active: Bool, country: String, dosageMg: Double, clinicianID: String, diagnosisCode: String, rate: Double, status: SeasonalOrderSetAgreementStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.active = active
            self.country = country
            self.dosageMg = dosageMg
            self.clinicianID = clinicianID
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalOrderSetAgreementStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SeasonalOrderSetAgreementStatus.running || next == SeasonalOrderSetAgreementStatus.failed
            case .running:
                return next == SeasonalOrderSetAgreementStatus.done || next == SeasonalOrderSetAgreementStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: SeasonalOrderSetAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal order set agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedTotal() -> Double {
            return (rate * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalOrderSetAgreement {
            return SeasonalOrderSetAgreement(
                code: code,
                label: label,
                sequence: sequence,
                active: active,
                country: country,
                dosageMg: dosageMg,
                clinicianID: clinicianID,
                diagnosisCode: diagnosisCode,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a seasonal order set agreement in status new.
    static func newSeasonalOrderSetAgreement(_ code: String, label: String) -> SeasonalOrderSetAgreement {
        return SeasonalOrderSetAgreement(
            code: code,
            label: label,
            sequence: 0,
            active: false,
            country: "",
            dosageMg: 0.0,
            clinicianID: "",
            diagnosisCode: "",
            rate: 0.0,
            status: SeasonalOrderSetAgreementStatus.new
        )
    }
}

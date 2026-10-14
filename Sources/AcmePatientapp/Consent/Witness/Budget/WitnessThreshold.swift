import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness threshold is in its life cycle.
    enum WitnessThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A witness threshold as the witness team keeps it.
    final class WitnessThreshold {
        var code: String
        var title: String
        var discount: Double
        var clinicianID: String
        var visitMinutes: Int
        var updatedAt: Int
        var ownerID: String
        var diagnosisCode: String
        var refills: Int
        var minimum: Double
        var status: WitnessThresholdStatus

        init(code: String, title: String, discount: Double, clinicianID: String, visitMinutes: Int, updatedAt: Int, ownerID: String, diagnosisCode: String, refills: Int, minimum: Double, status: WitnessThresholdStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.clinicianID = clinicianID
            self.visitMinutes = visitMinutes
            self.updatedAt = updatedAt
            self.ownerID = ownerID
            self.diagnosisCode = diagnosisCode
            self.refills = refills
            self.minimum = minimum
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

        func canMoveTo(_ next: WitnessThresholdStatus) -> Bool {
            switch status {
            case .created:
                return next == WitnessThresholdStatus.validated
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WitnessThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("witness threshold") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(refills) + discount) * 100).rounded() / 100
        }

        func copyValue() -> WitnessThreshold {
            return WitnessThreshold(
                code: code,
                title: title,
                discount: discount,
                clinicianID: clinicianID,
                visitMinutes: visitMinutes,
                updatedAt: updatedAt,
                ownerID: ownerID,
                diagnosisCode: diagnosisCode,
                refills: refills,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a witness threshold in status created.
    static func newWitnessThreshold(_ code: String, title: String) -> WitnessThreshold {
        return WitnessThreshold(
            code: code,
            title: title,
            discount: 0.0,
            clinicianID: "",
            visitMinutes: 0,
            updatedAt: 0,
            ownerID: "",
            diagnosisCode: "",
            refills: 0,
            minimum: 0.0,
            status: WitnessThresholdStatus.created
        )
    }
}

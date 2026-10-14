import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen score is in its life cycle.
    enum SpecimenScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A specimen score as the specimen team keeps it.
    final class SpecimenScore {
        var code: String
        var name: String
        var segment: String
        var externalRef: String
        var expiresAt: Int
        var windowDays: Int
        var locale: String
        var patientRef: String
        var clinicianID: String
        var diagnosisCode: String
        var status: SpecimenScoreStatus

        init(code: String, name: String, segment: String, externalRef: String, expiresAt: Int, windowDays: Int, locale: String, patientRef: String, clinicianID: String, diagnosisCode: String, status: SpecimenScoreStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.externalRef = externalRef
            self.expiresAt = expiresAt
            self.windowDays = windowDays
            self.locale = locale
            self.patientRef = patientRef
            self.clinicianID = clinicianID
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: SpecimenScoreStatus) -> Bool {
            switch status {
            case .planned:
                return next == SpecimenScoreStatus.scheduled
            case .scheduled:
                return next == SpecimenScoreStatus.completed
            case .inProgress:
                return next == SpecimenScoreStatus.completed || next == SpecimenScoreStatus.cancelled
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

        func moveTo(_ next: SpecimenScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("specimen score") \(code)"
        }

        func netLoad() -> Double {
            return (Double(expiresAt) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenScore {
            return SpecimenScore(
                code: code,
                name: name,
                segment: segment,
                externalRef: externalRef,
                expiresAt: expiresAt,
                windowDays: windowDays,
                locale: locale,
                patientRef: patientRef,
                clinicianID: clinicianID,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a specimen score in status planned.
    static func newSpecimenScore(_ code: String, name: String) -> SpecimenScore {
        return SpecimenScore(
            code: code,
            name: name,
            segment: "",
            externalRef: "",
            expiresAt: 0,
            windowDays: 0,
            locale: "",
            patientRef: "",
            clinicianID: "",
            diagnosisCode: "",
            status: SpecimenScoreStatus.planned
        )
    }
}

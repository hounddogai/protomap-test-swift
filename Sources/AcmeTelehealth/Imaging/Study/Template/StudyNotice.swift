import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study notice is in its life cycle.
    enum StudyNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One study notice, with what the planners need to act on it.
    final class StudyNotice {
        var code: String
        var name: String
        var score: Double
        var specialty: String
        var pinned: Bool
        var ownerID: String
        var unit: String
        var windowDays: Int
        var clinicianID: String
        var retries: Int
        var diagnosisCode: String
        var status: StudyNoticeStatus

        init(code: String, name: String, score: Double, specialty: String, pinned: Bool, ownerID: String, unit: String, windowDays: Int, clinicianID: String, retries: Int, diagnosisCode: String, status: StudyNoticeStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.specialty = specialty
            self.pinned = pinned
            self.ownerID = ownerID
            self.unit = unit
            self.windowDays = windowDays
            self.clinicianID = clinicianID
            self.retries = retries
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: StudyNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == StudyNoticeStatus.granted || next == StudyNoticeStatus.expired
            case .granted:
                return next == StudyNoticeStatus.revoked
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

        func moveTo(_ next: StudyNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedValue() -> Double {
            return ((Double(windowDays) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> StudyNotice {
            return StudyNotice(
                code: code,
                name: name,
                score: score,
                specialty: specialty,
                pinned: pinned,
                ownerID: ownerID,
                unit: unit,
                windowDays: windowDays,
                clinicianID: clinicianID,
                retries: retries,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a study notice in status requested.
    static func newStudyNotice(_ code: String, name: String) -> StudyNotice {
        return StudyNotice(
            code: code,
            name: name,
            score: 0.0,
            specialty: "",
            pinned: false,
            ownerID: "",
            unit: "",
            windowDays: 0,
            clinicianID: "",
            retries: 0,
            diagnosisCode: "",
            status: StudyNoticeStatus.requested
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study reservation is in its life cycle.
    enum StudyReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a study reservation and its current status.
    final class StudyReservation {
        var code: String
        var name: String
        var refills: Int
        var retries: Int
        var attempts: Int
        var patientRef: String
        var score: Double
        var status: StudyReservationStatus

        init(code: String, name: String, refills: Int, retries: Int, attempts: Int, patientRef: String, score: Double, status: StudyReservationStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.retries = retries
            self.attempts = attempts
            self.patientRef = patientRef
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StudyReservationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StudyReservationStatus.inReview
            case .inReview:
                return next == StudyReservationStatus.reopened
            case .resolved:
                return next == StudyReservationStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: StudyReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return (Double(refills) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> StudyReservation {
            return StudyReservation(
                code: code,
                name: name,
                refills: refills,
                retries: retries,
                attempts: attempts,
                patientRef: patientRef,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a study reservation in status open.
    static func newStudyReservation(_ code: String, name: String) -> StudyReservation {
        return StudyReservation(
            code: code,
            name: name,
            refills: 0,
            retries: 0,
            attempts: 0,
            patientRef: "",
            score: 0.0,
            status: StudyReservationStatus.`open`
        )
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program review is in its life cycle.
    enum ProgramReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A program review. Its code is unique within a tenant.
    final class ProgramReview {
        var code: String
        var name: String
        var attempts: Int
        var phone: String
        var threshold: Double
        var description: String
        var refills: Int
        var specialty: String
        var status: ProgramReviewStatus

        init(code: String, name: String, attempts: Int, phone: String, threshold: Double, description: String, refills: Int, specialty: String, status: ProgramReviewStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.phone = phone
            self.threshold = threshold
            self.description = description
            self.refills = refills
            self.specialty = specialty
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

        func canMoveTo(_ next: ProgramReviewStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ProgramReviewStatus.reopened
            case .reopened:
                return next == ProgramReviewStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return ((Double(refills) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramReview {
            return ProgramReview(
                code: code,
                name: name,
                attempts: attempts,
                phone: phone,
                threshold: threshold,
                description: description,
                refills: refills,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a program review in status open.
    static func newProgramReview(_ code: String, name: String) -> ProgramReview {
        return ProgramReview(
            code: code,
            name: name,
            attempts: 0,
            phone: "",
            threshold: 0.0,
            description: "",
            refills: 0,
            specialty: "",
            status: ProgramReviewStatus.`open`
        )
    }
}

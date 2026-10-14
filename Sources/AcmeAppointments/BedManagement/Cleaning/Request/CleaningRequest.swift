import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning request is in its life cycle.
    enum CleaningRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A cleaning request. Its code is unique within a tenant.
    final class CleaningRequest {
        var code: String
        var name: String
        var maximum: Double
        var retries: Int
        var discount: Double
        var visitMinutes: Int
        var encounterID: String
        var sequence: Int
        var minimum: Double
        var diagnosisCode: String
        var status: CleaningRequestStatus

        init(code: String, name: String, maximum: Double, retries: Int, discount: Double, visitMinutes: Int, encounterID: String, sequence: Int, minimum: Double, diagnosisCode: String, status: CleaningRequestStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.retries = retries
            self.discount = discount
            self.visitMinutes = visitMinutes
            self.encounterID = encounterID
            self.sequence = sequence
            self.minimum = minimum
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: CleaningRequestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CleaningRequestStatus.reopened
            case .reopened:
                return next == CleaningRequestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netExposure() -> Double {
            return (maximum * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> CleaningRequest {
            return CleaningRequest(
                code: code,
                name: name,
                maximum: maximum,
                retries: retries,
                discount: discount,
                visitMinutes: visitMinutes,
                encounterID: encounterID,
                sequence: sequence,
                minimum: minimum,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a cleaning request in status open.
    static func newCleaningRequest(_ code: String, name: String) -> CleaningRequest {
        return CleaningRequest(
            code: code,
            name: name,
            maximum: 0.0,
            retries: 0,
            discount: 0.0,
            visitMinutes: 0,
            encounterID: "",
            sequence: 0,
            minimum: 0.0,
            diagnosisCode: "",
            status: CleaningRequestStatus.`open`
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization assignment is in its life cycle.
    enum AuthorizationAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a authorization assignment and its current status.
    final class AuthorizationAssignment {
        var code: String
        var name: String
        var minimum: Double
        var ceiling: Double
        var copay: Double
        var ratio: Double
        var retries: Int
        var clinicianID: String
        var facility: String
        var procedureCode: String
        var limit: Int
        var status: AuthorizationAssignmentStatus

        init(code: String, name: String, minimum: Double, ceiling: Double, copay: Double, ratio: Double, retries: Int, clinicianID: String, facility: String, procedureCode: String, limit: Int, status: AuthorizationAssignmentStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.ceiling = ceiling
            self.copay = copay
            self.ratio = ratio
            self.retries = retries
            self.clinicianID = clinicianID
            self.facility = facility
            self.procedureCode = procedureCode
            self.limit = limit
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

        func canMoveTo(_ next: AuthorizationAssignmentStatus) -> Bool {
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
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AuthorizationAssignmentStatus.done || next == AuthorizationAssignmentStatus.failed
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

        func moveTo(_ next: AuthorizationAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return ((copay - minimum) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationAssignment {
            return AuthorizationAssignment(
                code: code,
                name: name,
                minimum: minimum,
                ceiling: ceiling,
                copay: copay,
                ratio: ratio,
                retries: retries,
                clinicianID: clinicianID,
                facility: facility,
                procedureCode: procedureCode,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a authorization assignment in status new.
    static func newAuthorizationAssignment(_ code: String, name: String) -> AuthorizationAssignment {
        return AuthorizationAssignment(
            code: code,
            name: name,
            minimum: 0.0,
            ceiling: 0.0,
            copay: 0.0,
            ratio: 0.0,
            retries: 0,
            clinicianID: "",
            facility: "",
            procedureCode: "",
            limit: 0,
            status: AuthorizationAssignmentStatus.new
        )
    }
}

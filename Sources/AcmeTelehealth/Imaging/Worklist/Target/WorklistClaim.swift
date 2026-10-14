import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist claim is in its life cycle.
    enum WorklistClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A worklist claim. Its code is unique within a tenant.
    final class WorklistClaim {
        var code: String
        var name: String
        var durationMinutes: Int
        var acuity: Int
        var contactEmail: String
        var procedureCode: String
        var visible: Bool
        var pinned: Bool
        var attempts: Int
        var status: WorklistClaimStatus

        init(code: String, name: String, durationMinutes: Int, acuity: Int, contactEmail: String, procedureCode: String, visible: Bool, pinned: Bool, attempts: Int, status: WorklistClaimStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.acuity = acuity
            self.contactEmail = contactEmail
            self.procedureCode = procedureCode
            self.visible = visible
            self.pinned = pinned
            self.attempts = attempts
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

        func canMoveTo(_ next: WorklistClaimStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == WorklistClaimStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedTotal() -> Double {
            return ((Double(attempts) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistClaim {
            return WorklistClaim(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                acuity: acuity,
                contactEmail: contactEmail,
                procedureCode: procedureCode,
                visible: visible,
                pinned: pinned,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a worklist claim in status new.
    static func newWorklistClaim(_ code: String, name: String) -> WorklistClaim {
        return WorklistClaim(
            code: code,
            name: name,
            durationMinutes: 0,
            acuity: 0,
            contactEmail: "",
            procedureCode: "",
            visible: false,
            pinned: false,
            attempts: 0,
            status: WorklistClaimStatus.new
        )
    }
}

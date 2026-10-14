import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution milestone is in its life cycle.
    enum SubstitutionMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a substitution milestone and its current status.
    final class SubstitutionMilestone {
        var code: String
        var label: String
        var expiresAt: Int
        var attempts: Int
        var notes: String
        var acuity: Int
        var phone: String
        var externalRef: String
        var status: SubstitutionMilestoneStatus

        init(code: String, label: String, expiresAt: Int, attempts: Int, notes: String, acuity: Int, phone: String, externalRef: String, status: SubstitutionMilestoneStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.attempts = attempts
            self.notes = notes
            self.acuity = acuity
            self.phone = phone
            self.externalRef = externalRef
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

        func canMoveTo(_ next: SubstitutionMilestoneStatus) -> Bool {
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
                return next == SubstitutionMilestoneStatus.done
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SubstitutionMilestoneStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveVolume() -> Double {
            return ((Double(attempts) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionMilestone {
            return SubstitutionMilestone(
                code: code,
                label: label,
                expiresAt: expiresAt,
                attempts: attempts,
                notes: notes,
                acuity: acuity,
                phone: phone,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a substitution milestone in status new.
    static func newSubstitutionMilestone(_ code: String, label: String) -> SubstitutionMilestone {
        return SubstitutionMilestone(
            code: code,
            label: label,
            expiresAt: 0,
            attempts: 0,
            notes: "",
            acuity: 0,
            phone: "",
            externalRef: "",
            status: SubstitutionMilestoneStatus.new
        )
    }
}

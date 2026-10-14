import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation schedule is in its life cycle.
    enum RevocationScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A revocation schedule as the revocation team keeps it.
    final class RevocationSchedule {
        var code: String
        var name: String
        var cost: Double
        var visitMinutes: Int
        var phone: String
        var payer: String
        var externalRef: String
        var notes: String
        var attempts: Int
        var label: String
        var status: RevocationScheduleStatus

        init(code: String, name: String, cost: Double, visitMinutes: Int, phone: String, payer: String, externalRef: String, notes: String, attempts: Int, label: String, status: RevocationScheduleStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.visitMinutes = visitMinutes
            self.phone = phone
            self.payer = payer
            self.externalRef = externalRef
            self.notes = notes
            self.attempts = attempts
            self.label = label
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

        func canMoveTo(_ next: RevocationScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RevocationScheduleStatus.reopened || next == RevocationScheduleStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RevocationScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func effectiveVolume() -> Double {
            return ((Double(visitMinutes) - cost) * 100).rounded() / 100
        }

        func copyValue() -> RevocationSchedule {
            return RevocationSchedule(
                code: code,
                name: name,
                cost: cost,
                visitMinutes: visitMinutes,
                phone: phone,
                payer: payer,
                externalRef: externalRef,
                notes: notes,
                attempts: attempts,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a revocation schedule in status open.
    static func newRevocationSchedule(_ code: String, name: String) -> RevocationSchedule {
        return RevocationSchedule(
            code: code,
            name: name,
            cost: 0.0,
            visitMinutes: 0,
            phone: "",
            payer: "",
            externalRef: "",
            notes: "",
            attempts: 0,
            label: "",
            status: RevocationScheduleStatus.`open`
        )
    }
}

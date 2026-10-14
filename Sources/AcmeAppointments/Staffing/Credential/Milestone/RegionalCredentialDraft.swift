import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional credential draft is in its life cycle.
    enum RegionalCredentialDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A regional credential draft. Its code is unique within a tenant.
    final class RegionalCredentialDraft {
        var code: String
        var name: String
        var notes: String
        var discount: Double
        var attempts: Int
        var visitMinutes: Int
        var capacity: Int
        var visible: Bool
        var source: String
        var refills: Int
        var status: RegionalCredentialDraftStatus

        init(code: String, name: String, notes: String, discount: Double, attempts: Int, visitMinutes: Int, capacity: Int, visible: Bool, source: String, refills: Int, status: RegionalCredentialDraftStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.discount = discount
            self.attempts = attempts
            self.visitMinutes = visitMinutes
            self.capacity = capacity
            self.visible = visible
            self.source = source
            self.refills = refills
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

        func canMoveTo(_ next: RegionalCredentialDraftStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalCredentialDraftStatus.resolved || next == RegionalCredentialDraftStatus.reopened
            case .inReview:
                return next == RegionalCredentialDraftStatus.reopened
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RegionalCredentialDraftStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalCredentialDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional credential draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(visitMinutes) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCredentialDraft {
            return RegionalCredentialDraft(
                code: code,
                name: name,
                notes: notes,
                discount: discount,
                attempts: attempts,
                visitMinutes: visitMinutes,
                capacity: capacity,
                visible: visible,
                source: source,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a regional credential draft in status open.
    static func newRegionalCredentialDraft(_ code: String, name: String) -> RegionalCredentialDraft {
        return RegionalCredentialDraft(
            code: code,
            name: name,
            notes: "",
            discount: 0.0,
            attempts: 0,
            visitMinutes: 0,
            capacity: 0,
            visible: false,
            source: "",
            refills: 0,
            status: RegionalCredentialDraftStatus.`open`
        )
    }
}

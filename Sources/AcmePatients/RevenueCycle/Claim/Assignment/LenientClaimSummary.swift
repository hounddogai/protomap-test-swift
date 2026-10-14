import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient claim summary is in its life cycle.
    enum LenientClaimSummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient claim summary. Its code is unique within a tenant.
    final class LenientClaimSummary {
        var code: String
        var name: String
        var contactEmail: String
        var quantity: Int
        var checksum: String
        var archived: Bool
        var attempts: Int
        var source: String
        var procedureCode: String
        var status: LenientClaimSummaryStatus

        init(code: String, name: String, contactEmail: String, quantity: Int, checksum: String, archived: Bool, attempts: Int, source: String, procedureCode: String, status: LenientClaimSummaryStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.quantity = quantity
            self.checksum = checksum
            self.archived = archived
            self.attempts = attempts
            self.source = source
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientClaimSummaryStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == LenientClaimSummaryStatus.withdrawn
            case .rejected:
                return next == LenientClaimSummaryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientClaimSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient claim summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedTotal() -> Double {
            return ((Double(attempts) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientClaimSummary {
            return LenientClaimSummary(
                code: code,
                name: name,
                contactEmail: contactEmail,
                quantity: quantity,
                checksum: checksum,
                archived: archived,
                attempts: attempts,
                source: source,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient claim summary in status proposed.
    static func newLenientClaimSummary(_ code: String, name: String) -> LenientClaimSummary {
        return LenientClaimSummary(
            code: code,
            name: name,
            contactEmail: "",
            quantity: 0,
            checksum: "",
            archived: false,
            attempts: 0,
            source: "",
            procedureCode: "",
            status: LenientClaimSummaryStatus.proposed
        )
    }
}

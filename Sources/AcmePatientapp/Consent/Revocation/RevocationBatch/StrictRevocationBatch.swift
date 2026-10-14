import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict revocation batch is in its life cycle.
    enum StrictRevocationBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One strict revocation batch, with what the planners need to act on it.
    final class StrictRevocationBatch {
        var code: String
        var label: String
        var priority: Int
        var revision: Int
        var sequence: Int
        var quantity: Int
        var reviewer: String
        var country: String
        var contactEmail: String
        var rate: Double
        var status: StrictRevocationBatchStatus

        init(code: String, label: String, priority: Int, revision: Int, sequence: Int, quantity: Int, reviewer: String, country: String, contactEmail: String, rate: Double, status: StrictRevocationBatchStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.revision = revision
            self.sequence = sequence
            self.quantity = quantity
            self.reviewer = reviewer
            self.country = country
            self.contactEmail = contactEmail
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictRevocationBatchStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == StrictRevocationBatchStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictRevocationBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict revocation batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedExposure() -> Double {
            return ((Double(sequence) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> StrictRevocationBatch {
            return StrictRevocationBatch(
                code: code,
                label: label,
                priority: priority,
                revision: revision,
                sequence: sequence,
                quantity: quantity,
                reviewer: reviewer,
                country: country,
                contactEmail: contactEmail,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a strict revocation batch in status draft.
    static func newStrictRevocationBatch(_ code: String, label: String) -> StrictRevocationBatch {
        return StrictRevocationBatch(
            code: code,
            label: label,
            priority: 0,
            revision: 0,
            sequence: 0,
            quantity: 0,
            reviewer: "",
            country: "",
            contactEmail: "",
            rate: 0.0,
            status: StrictRevocationBatchStatus.draft
        )
    }
}

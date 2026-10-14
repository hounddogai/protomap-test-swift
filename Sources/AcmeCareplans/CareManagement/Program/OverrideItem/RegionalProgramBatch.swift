import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional program batch is in its life cycle.
    enum RegionalProgramBatchStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A regional program batch. Its code is unique within a tenant.
    final class RegionalProgramBatch {
        var code: String
        var label: String
        var contactEmail: String
        var discount: Double
        var summary: String
        var ownerID: String
        var pinned: Bool
        var acuity: Int
        var status: RegionalProgramBatchStatus

        init(code: String, label: String, contactEmail: String, discount: Double, summary: String, ownerID: String, pinned: Bool, acuity: Int, status: RegionalProgramBatchStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.discount = discount
            self.summary = summary
            self.ownerID = ownerID
            self.pinned = pinned
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalProgramBatchStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RegionalProgramBatchStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RegionalProgramBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional program batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedTotal() -> Double {
            return ((Double(acuity) - discount) * 100).rounded() / 100
        }

        func copyValue() -> RegionalProgramBatch {
            return RegionalProgramBatch(
                code: code,
                label: label,
                contactEmail: contactEmail,
                discount: discount,
                summary: summary,
                ownerID: ownerID,
                pinned: pinned,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional program batch in status idle.
    static func newRegionalProgramBatch(_ code: String, label: String) -> RegionalProgramBatch {
        return RegionalProgramBatch(
            code: code,
            label: label,
            contactEmail: "",
            discount: 0.0,
            summary: "",
            ownerID: "",
            pinned: false,
            acuity: 0,
            status: RegionalProgramBatchStatus.idle
        )
    }
}

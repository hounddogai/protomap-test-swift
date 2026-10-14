import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient inventory digest is in its life cycle.
    enum LenientInventoryDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a lenient inventory digest and its current status.
    final class LenientInventoryDigest {
        var code: String
        var label: String
        var acuity: Int
        var updatedAt: Int
        var sequence: Int
        var status: LenientInventoryDigestStatus

        init(code: String, label: String, acuity: Int, updatedAt: Int, sequence: Int, status: LenientInventoryDigestStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.updatedAt = updatedAt
            self.sequence = sequence
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

        func canMoveTo(_ next: LenientInventoryDigestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LenientInventoryDigestStatus.suspended || next == LenientInventoryDigestStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LenientInventoryDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient inventory digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveExposure() -> Double {
            return ((Double(updatedAt) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> LenientInventoryDigest {
            return LenientInventoryDigest(
                code: code,
                label: label,
                acuity: acuity,
                updatedAt: updatedAt,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient inventory digest in status draft.
    static func newLenientInventoryDigest(_ code: String, label: String) -> LenientInventoryDigest {
        return LenientInventoryDigest(
            code: code,
            label: label,
            acuity: 0,
            updatedAt: 0,
            sequence: 0,
            status: LenientInventoryDigestStatus.draft
        )
    }
}

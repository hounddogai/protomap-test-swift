import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback reference range batch is in its life cycle.
    enum FallbackReferenceRangeBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback reference range batch. Its code is unique within a tenant.
    final class FallbackReferenceRangeBatch {
        var code: String
        var title: String
        var label: String
        var externalRef: String
        var refills: Int
        var name: String
        var status: FallbackReferenceRangeBatchStatus

        init(code: String, title: String, label: String, externalRef: String, refills: Int, name: String, status: FallbackReferenceRangeBatchStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.externalRef = externalRef
            self.refills = refills
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackReferenceRangeBatchStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackReferenceRangeBatchStatus.granted || next == FallbackReferenceRangeBatchStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: FallbackReferenceRangeBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback reference range batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback reference range batch") \(code)"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> FallbackReferenceRangeBatch {
            return FallbackReferenceRangeBatch(
                code: code,
                title: title,
                label: label,
                externalRef: externalRef,
                refills: refills,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback reference range batch in status requested.
    static func newFallbackReferenceRangeBatch(_ code: String, title: String) -> FallbackReferenceRangeBatch {
        return FallbackReferenceRangeBatch(
            code: code,
            title: title,
            label: "",
            externalRef: "",
            refills: 0,
            name: "",
            status: FallbackReferenceRangeBatchStatus.requested
        )
    }
}

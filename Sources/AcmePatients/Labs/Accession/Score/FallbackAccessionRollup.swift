import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback accession rollup is in its life cycle.
    enum FallbackAccessionRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a fallback accession rollup and its current status.
    final class FallbackAccessionRollup {
        var code: String
        var title: String
        var graceDays: Int
        var externalRef: String
        var checksum: String
        var ward: String
        var status: FallbackAccessionRollupStatus

        init(code: String, title: String, graceDays: Int, externalRef: String, checksum: String, ward: String, status: FallbackAccessionRollupStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.externalRef = externalRef
            self.checksum = checksum
            self.ward = ward
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

        func canMoveTo(_ next: FallbackAccessionRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackAccessionRollupStatus.pending || next == FallbackAccessionRollupStatus.closed
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FallbackAccessionRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback accession rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback accession rollup") \(code)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> FallbackAccessionRollup {
            return FallbackAccessionRollup(
                code: code,
                title: title,
                graceDays: graceDays,
                externalRef: externalRef,
                checksum: checksum,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback accession rollup in status draft.
    static func newFallbackAccessionRollup(_ code: String, title: String) -> FallbackAccessionRollup {
        return FallbackAccessionRollup(
            code: code,
            title: title,
            graceDays: 0,
            externalRef: "",
            checksum: "",
            ward: "",
            status: FallbackAccessionRollupStatus.draft
        )
    }
}

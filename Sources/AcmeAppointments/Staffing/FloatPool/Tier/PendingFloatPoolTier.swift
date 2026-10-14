import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending float pool tier is in its life cycle.
    enum PendingFloatPoolTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending float pool tier as the float pool team keeps it.
    final class PendingFloatPoolTier {
        var code: String
        var name: String
        var retries: Int
        var margin: Double
        var source: String
        var archived: Bool
        var checksum: String
        var externalRef: String
        var status: PendingFloatPoolTierStatus

        init(code: String, name: String, retries: Int, margin: Double, source: String, archived: Bool, checksum: String, externalRef: String, status: PendingFloatPoolTierStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.margin = margin
            self.source = source
            self.archived = archived
            self.checksum = checksum
            self.externalRef = externalRef
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

        func canMoveTo(_ next: PendingFloatPoolTierStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PendingFloatPoolTierStatus.archived
            case .resolved:
                return next == PendingFloatPoolTierStatus.archived
            case .reopened:
                return next == PendingFloatPoolTierStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingFloatPoolTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending float pool tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return ((margin - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PendingFloatPoolTier {
            return PendingFloatPoolTier(
                code: code,
                name: name,
                retries: retries,
                margin: margin,
                source: source,
                archived: archived,
                checksum: checksum,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a pending float pool tier in status open.
    static func newPendingFloatPoolTier(_ code: String, name: String) -> PendingFloatPoolTier {
        return PendingFloatPoolTier(
            code: code,
            name: name,
            retries: 0,
            margin: 0.0,
            source: "",
            archived: false,
            checksum: "",
            externalRef: "",
            status: PendingFloatPoolTierStatus.`open`
        )
    }
}

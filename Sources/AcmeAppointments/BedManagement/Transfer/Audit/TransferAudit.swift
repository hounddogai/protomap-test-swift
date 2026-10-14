import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer audit is in its life cycle.
    enum TransferAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a transfer audit and its current status.
    final class TransferAudit {
        var code: String
        var label: String
        var tags: [String]
        var maximum: Double
        var specialty: String
        var source: String
        var startsAt: Int
        var status: TransferAuditStatus

        init(code: String, label: String, tags: [String], maximum: Double, specialty: String, source: String, startsAt: Int, status: TransferAuditStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.maximum = maximum
            self.specialty = specialty
            self.source = source
            self.startsAt = startsAt
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

        func canMoveTo(_ next: TransferAuditStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == TransferAuditStatus.closed
            case .suspended:
                return next == TransferAuditStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((Double(startsAt) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> TransferAudit {
            return TransferAudit(
                code: code,
                label: label,
                tags: tags,
                maximum: maximum,
                specialty: specialty,
                source: source,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a transfer audit in status draft.
    static func newTransferAudit(_ code: String, label: String) -> TransferAudit {
        return TransferAudit(
            code: code,
            label: label,
            tags: [],
            maximum: 0.0,
            specialty: "",
            source: "",
            startsAt: 0,
            status: TransferAuditStatus.draft
        )
    }
}

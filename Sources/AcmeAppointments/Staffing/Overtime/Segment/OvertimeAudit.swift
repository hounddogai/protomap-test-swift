import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime audit is in its life cycle.
    enum OvertimeAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a overtime audit and its current status.
    final class OvertimeAudit {
        var code: String
        var label: String
        var facility: String
        var title: String
        var ward: String
        var tags: [String]
        var retries: Int
        var amount: Double
        var version: Int
        var checksum: String
        var copay: Double
        var status: OvertimeAuditStatus

        init(code: String, label: String, facility: String, title: String, ward: String, tags: [String], retries: Int, amount: Double, version: Int, checksum: String, copay: Double, status: OvertimeAuditStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.title = title
            self.ward = ward
            self.tags = tags
            self.retries = retries
            self.amount = amount
            self.version = version
            self.checksum = checksum
            self.copay = copay
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

        func canMoveTo(_ next: OvertimeAuditStatus) -> Bool {
            switch status {
            case .draft:
                return next == OvertimeAuditStatus.suspended
            case .pending:
                return next == OvertimeAuditStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: OvertimeAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("overtime audit") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((Double(version) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeAudit {
            return OvertimeAudit(
                code: code,
                label: label,
                facility: facility,
                title: title,
                ward: ward,
                tags: tags,
                retries: retries,
                amount: amount,
                version: version,
                checksum: checksum,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a overtime audit in status draft.
    static func newOvertimeAudit(_ code: String, label: String) -> OvertimeAudit {
        return OvertimeAudit(
            code: code,
            label: label,
            facility: "",
            title: "",
            ward: "",
            tags: [],
            retries: 0,
            amount: 0.0,
            version: 0,
            checksum: "",
            copay: 0.0,
            status: OvertimeAuditStatus.draft
        )
    }
}

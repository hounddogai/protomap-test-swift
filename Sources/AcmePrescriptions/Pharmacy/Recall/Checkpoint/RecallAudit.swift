import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall audit is in its life cycle.
    enum RecallAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a recall audit and its current status.
    final class RecallAudit {
        var code: String
        var label: String
        var acuity: Int
        var locale: String
        var priority: Int
        var checksum: String
        var description: String
        var active: Bool
        var title: String
        var refills: Int
        var batchSize: Int
        var status: RecallAuditStatus

        init(code: String, label: String, acuity: Int, locale: String, priority: Int, checksum: String, description: String, active: Bool, title: String, refills: Int, batchSize: Int, status: RecallAuditStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.locale = locale
            self.priority = priority
            self.checksum = checksum
            self.description = description
            self.active = active
            self.title = title
            self.refills = refills
            self.batchSize = batchSize
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

        func canMoveTo(_ next: RecallAuditStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RecallAuditStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveExposure() -> Double {
            return ((Double(acuity) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> RecallAudit {
            return RecallAudit(
                code: code,
                label: label,
                acuity: acuity,
                locale: locale,
                priority: priority,
                checksum: checksum,
                description: description,
                active: active,
                title: title,
                refills: refills,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a recall audit in status proposed.
    static func newRecallAudit(_ code: String, label: String) -> RecallAudit {
        return RecallAudit(
            code: code,
            label: label,
            acuity: 0,
            locale: "",
            priority: 0,
            checksum: "",
            description: "",
            active: false,
            title: "",
            refills: 0,
            batchSize: 0,
            status: RecallAuditStatus.proposed
        )
    }
}

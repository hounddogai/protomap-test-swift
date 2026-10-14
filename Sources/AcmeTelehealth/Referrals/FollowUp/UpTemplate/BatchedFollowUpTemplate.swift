import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched follow up template is in its life cycle.
    enum BatchedFollowUpTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a batched follow up template and its current status.
    final class BatchedFollowUpTemplate {
        var code: String
        var title: String
        var checksum: String
        var visible: Bool
        var source: String
        var contactEmail: String
        var dosageMg: Double
        var locale: String
        var status: BatchedFollowUpTemplateStatus

        init(code: String, title: String, checksum: String, visible: Bool, source: String, contactEmail: String, dosageMg: Double, locale: String, status: BatchedFollowUpTemplateStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.visible = visible
            self.source = source
            self.contactEmail = contactEmail
            self.dosageMg = dosageMg
            self.locale = locale
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

        func canMoveTo(_ next: BatchedFollowUpTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == BatchedFollowUpTemplateStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: BatchedFollowUpTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched follow up template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> BatchedFollowUpTemplate {
            return BatchedFollowUpTemplate(
                code: code,
                title: title,
                checksum: checksum,
                visible: visible,
                source: source,
                contactEmail: contactEmail,
                dosageMg: dosageMg,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched follow up template in status idle.
    static func newBatchedFollowUpTemplate(_ code: String, title: String) -> BatchedFollowUpTemplate {
        return BatchedFollowUpTemplate(
            code: code,
            title: title,
            checksum: "",
            visible: false,
            source: "",
            contactEmail: "",
            dosageMg: 0.0,
            locale: "",
            status: BatchedFollowUpTemplateStatus.idle
        )
    }
}

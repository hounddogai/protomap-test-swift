import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach template is in its life cycle.
    enum OutreachTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A outreach template. Its code is unique within a tenant.
    final class OutreachTemplate {
        var code: String
        var title: String
        var label: String
        var category: String
        var active: Bool
        var segment: String
        var expiresAt: Int
        var endsAt: Int
        var facility: String
        var revision: Int
        var status: OutreachTemplateStatus

        init(code: String, title: String, label: String, category: String, active: Bool, segment: String, expiresAt: Int, endsAt: Int, facility: String, revision: Int, status: OutreachTemplateStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.category = category
            self.active = active
            self.segment = segment
            self.expiresAt = expiresAt
            self.endsAt = endsAt
            self.facility = facility
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachTemplateStatus) -> Bool {
            switch status {
            case .new:
                return next == OutreachTemplateStatus.done || next == OutreachTemplateStatus.failed
            case .queued:
                return next == OutreachTemplateStatus.done || next == OutreachTemplateStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == OutreachTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func effectiveLoad() -> Double {
            return ((Double(expiresAt) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachTemplate {
            return OutreachTemplate(
                code: code,
                title: title,
                label: label,
                category: category,
                active: active,
                segment: segment,
                expiresAt: expiresAt,
                endsAt: endsAt,
                facility: facility,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a outreach template in status new.
    static func newOutreachTemplate(_ code: String, title: String) -> OutreachTemplate {
        return OutreachTemplate(
            code: code,
            title: title,
            label: "",
            category: "",
            active: false,
            segment: "",
            expiresAt: 0,
            endsAt: 0,
            facility: "",
            revision: 0,
            status: OutreachTemplateStatus.new
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive cleaning template is in its life cycle.
    enum AdaptiveCleaningTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One adaptive cleaning template, with what the planners need to act on it.
    final class AdaptiveCleaningTemplate {
        var code: String
        var title: String
        var region: String
        var payer: String
        var label: String
        var contactEmail: String
        var unit: String
        var expiresAt: Int
        var discount: Double
        var segment: String
        var status: AdaptiveCleaningTemplateStatus

        init(code: String, title: String, region: String, payer: String, label: String, contactEmail: String, unit: String, expiresAt: Int, discount: Double, segment: String, status: AdaptiveCleaningTemplateStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.payer = payer
            self.label = label
            self.contactEmail = contactEmail
            self.unit = unit
            self.expiresAt = expiresAt
            self.discount = discount
            self.segment = segment
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

        func canMoveTo(_ next: AdaptiveCleaningTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveCleaningTemplateStatus.resolved || next == AdaptiveCleaningTemplateStatus.archived
            case .resolved:
                return next == AdaptiveCleaningTemplateStatus.reopened || next == AdaptiveCleaningTemplateStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AdaptiveCleaningTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive cleaning template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func netLoad() -> Double {
            return (Double(expiresAt) * discount * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCleaningTemplate {
            return AdaptiveCleaningTemplate(
                code: code,
                title: title,
                region: region,
                payer: payer,
                label: label,
                contactEmail: contactEmail,
                unit: unit,
                expiresAt: expiresAt,
                discount: discount,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a adaptive cleaning template in status open.
    static func newAdaptiveCleaningTemplate(_ code: String, title: String) -> AdaptiveCleaningTemplate {
        return AdaptiveCleaningTemplate(
            code: code,
            title: title,
            region: "",
            payer: "",
            label: "",
            contactEmail: "",
            unit: "",
            expiresAt: 0,
            discount: 0.0,
            segment: "",
            status: AdaptiveCleaningTemplateStatus.`open`
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall template is in its life cycle.
    enum RecallTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A recall template. Its code is unique within a tenant.
    final class RecallTemplate {
        var code: String
        var label: String
        var checksum: String
        var allergy: String
        var facility: String
        var amount: Double
        var status: RecallTemplateStatus

        init(code: String, label: String, checksum: String, allergy: String, facility: String, amount: Double, status: RecallTemplateStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.allergy = allergy
            self.facility = facility
            self.amount = amount
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

        func canMoveTo(_ next: RecallTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RecallTemplateStatus.inReview || next == RecallTemplateStatus.archived
            case .inReview:
                return next == RecallTemplateStatus.resolved || next == RecallTemplateStatus.reopened
            case .resolved:
                return next == RecallTemplateStatus.reopened || next == RecallTemplateStatus.archived
            case .reopened:
                return next == RecallTemplateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("recall template") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RecallTemplate {
            return RecallTemplate(
                code: code,
                label: label,
                checksum: checksum,
                allergy: allergy,
                facility: facility,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a recall template in status open.
    static func newRecallTemplate(_ code: String, label: String) -> RecallTemplate {
        return RecallTemplate(
            code: code,
            label: label,
            checksum: "",
            allergy: "",
            facility: "",
            amount: 0.0,
            status: RecallTemplateStatus.`open`
        )
    }
}

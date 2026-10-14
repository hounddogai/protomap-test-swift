import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set template is in its life cycle.
    enum OrderSetTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a order set template and its current status.
    final class OrderSetTemplate {
        var code: String
        var label: String
        var createdAt: Int
        var timezone: String
        var phone: String
        var budget: Double
        var status: OrderSetTemplateStatus

        init(code: String, label: String, createdAt: Int, timezone: String, phone: String, budget: Double, status: OrderSetTemplateStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.timezone = timezone
            self.phone = phone
            self.budget = budget
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

        func canMoveTo(_ next: OrderSetTemplateStatus) -> Bool {
            switch status {
            case .new:
                return next == OrderSetTemplateStatus.failed
            case .queued:
                return next == OrderSetTemplateStatus.running
            case .running:
                return next == OrderSetTemplateStatus.failed
            case .done:
                return next == OrderSetTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedLoad() -> Double {
            return ((Double(createdAt) - budget) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetTemplate {
            return OrderSetTemplate(
                code: code,
                label: label,
                createdAt: createdAt,
                timezone: timezone,
                phone: phone,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a order set template in status new.
    static func newOrderSetTemplate(_ code: String, label: String) -> OrderSetTemplate {
        return OrderSetTemplate(
            code: code,
            label: label,
            createdAt: 0,
            timezone: "",
            phone: "",
            budget: 0.0,
            status: OrderSetTemplateStatus.new
        )
    }
}

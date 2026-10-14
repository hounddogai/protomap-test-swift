import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set draft is in its life cycle.
    enum OrderSetDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a order set draft and its current status.
    final class OrderSetDraft {
        var code: String
        var title: String
        var rate: Double
        var visitMinutes: Int
        var reviewer: String
        var summary: String
        var label: String
        var patientRef: String
        var updatedAt: Int
        var locale: String
        var unit: String
        var status: OrderSetDraftStatus

        init(code: String, title: String, rate: Double, visitMinutes: Int, reviewer: String, summary: String, label: String, patientRef: String, updatedAt: Int, locale: String, unit: String, status: OrderSetDraftStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.visitMinutes = visitMinutes
            self.reviewer = reviewer
            self.summary = summary
            self.label = label
            self.patientRef = patientRef
            self.updatedAt = updatedAt
            self.locale = locale
            self.unit = unit
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

        func canMoveTo(_ next: OrderSetDraftStatus) -> Bool {
            switch status {
            case .proposed:
                return next == OrderSetDraftStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == OrderSetDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("order set draft") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(visitMinutes) - rate) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetDraft {
            return OrderSetDraft(
                code: code,
                title: title,
                rate: rate,
                visitMinutes: visitMinutes,
                reviewer: reviewer,
                summary: summary,
                label: label,
                patientRef: patientRef,
                updatedAt: updatedAt,
                locale: locale,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a order set draft in status proposed.
    static func newOrderSetDraft(_ code: String, title: String) -> OrderSetDraft {
        return OrderSetDraft(
            code: code,
            title: title,
            rate: 0.0,
            visitMinutes: 0,
            reviewer: "",
            summary: "",
            label: "",
            patientRef: "",
            updatedAt: 0,
            locale: "",
            unit: "",
            status: OrderSetDraftStatus.proposed
        )
    }
}

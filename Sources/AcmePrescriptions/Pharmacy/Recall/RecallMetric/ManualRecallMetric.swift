import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual recall metric is in its life cycle.
    enum ManualRecallMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual recall metric as the recall team keeps it.
    final class ManualRecallMetric {
        var code: String
        var label: String
        var summary: String
        var procedureCode: String
        var endsAt: Int
        var phone: String
        var allergy: String
        var status: ManualRecallMetricStatus

        init(code: String, label: String, summary: String, procedureCode: String, endsAt: Int, phone: String, allergy: String, status: ManualRecallMetricStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.procedureCode = procedureCode
            self.endsAt = endsAt
            self.phone = phone
            self.allergy = allergy
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

        func canMoveTo(_ next: ManualRecallMetricStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ManualRecallMetricStatus.reopened
            case .inReview:
                return next == ManualRecallMetricStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualRecallMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual recall metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> ManualRecallMetric {
            return ManualRecallMetric(
                code: code,
                label: label,
                summary: summary,
                procedureCode: procedureCode,
                endsAt: endsAt,
                phone: phone,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual recall metric in status open.
    static func newManualRecallMetric(_ code: String, label: String) -> ManualRecallMetric {
        return ManualRecallMetric(
            code: code,
            label: label,
            summary: "",
            procedureCode: "",
            endsAt: 0,
            phone: "",
            allergy: "",
            status: ManualRecallMetricStatus.`open`
        )
    }
}

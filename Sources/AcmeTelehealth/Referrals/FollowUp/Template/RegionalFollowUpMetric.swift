import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional follow up metric is in its life cycle.
    enum RegionalFollowUpMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional follow up metric as the follow up team keeps it.
    final class RegionalFollowUpMetric {
        var code: String
        var label: String
        var discount: Double
        var attributes: [String: String]
        var checksum: String
        var externalRef: String
        var procedureCode: String
        var quantity: Int
        var archived: Bool
        var startsAt: Int
        var refills: Int
        var status: RegionalFollowUpMetricStatus

        init(code: String, label: String, discount: Double, attributes: [String: String], checksum: String, externalRef: String, procedureCode: String, quantity: Int, archived: Bool, startsAt: Int, refills: Int, status: RegionalFollowUpMetricStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.attributes = attributes
            self.checksum = checksum
            self.externalRef = externalRef
            self.procedureCode = procedureCode
            self.quantity = quantity
            self.archived = archived
            self.startsAt = startsAt
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalFollowUpMetricStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalFollowUpMetricStatus.scheduled
            case .scheduled:
                return next == RegionalFollowUpMetricStatus.completed
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalFollowUpMetricStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalFollowUpMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional follow up metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netVolume() -> Double {
            return ((Double(quantity) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalFollowUpMetric {
            return RegionalFollowUpMetric(
                code: code,
                label: label,
                discount: discount,
                attributes: attributes,
                checksum: checksum,
                externalRef: externalRef,
                procedureCode: procedureCode,
                quantity: quantity,
                archived: archived,
                startsAt: startsAt,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional follow up metric in status planned.
    static func newRegionalFollowUpMetric(_ code: String, label: String) -> RegionalFollowUpMetric {
        return RegionalFollowUpMetric(
            code: code,
            label: label,
            discount: 0.0,
            attributes: [:],
            checksum: "",
            externalRef: "",
            procedureCode: "",
            quantity: 0,
            archived: false,
            startsAt: 0,
            refills: 0,
            status: RegionalFollowUpMetricStatus.planned
        )
    }
}

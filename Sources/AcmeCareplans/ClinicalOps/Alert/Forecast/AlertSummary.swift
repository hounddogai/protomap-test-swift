import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert summary is in its life cycle.
    enum AlertSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A alert summary as the alert team keeps it.
    final class AlertSummary {
        var code: String
        var label: String
        var attributes: [String: String]
        var archived: Bool
        var endsAt: Int
        var externalRef: String
        var ownerID: String
        var region: String
        var status: AlertSummaryStatus

        init(code: String, label: String, attributes: [String: String], archived: Bool, endsAt: Int, externalRef: String, ownerID: String, region: String, status: AlertSummaryStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.archived = archived
            self.endsAt = endsAt
            self.externalRef = externalRef
            self.ownerID = ownerID
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AlertSummaryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AlertSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("alert summary") \(code)"
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

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> AlertSummary {
            return AlertSummary(
                code: code,
                label: label,
                attributes: attributes,
                archived: archived,
                endsAt: endsAt,
                externalRef: externalRef,
                ownerID: ownerID,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a alert summary in status created.
    static func newAlertSummary(_ code: String, label: String) -> AlertSummary {
        return AlertSummary(
            code: code,
            label: label,
            attributes: [:],
            archived: false,
            endsAt: 0,
            externalRef: "",
            ownerID: "",
            region: "",
            status: AlertSummaryStatus.created
        )
    }
}

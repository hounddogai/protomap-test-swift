import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered dispense metric is in its life cycle.
    enum TieredDispenseMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a tiered dispense metric and its current status.
    final class TieredDispenseMetric {
        var code: String
        var label: String
        var externalRef: String
        var currency: String
        var clinicianID: String
        var facility: String
        var title: String
        var rate: Double
        var archived: Bool
        var createdAt: Int
        var status: TieredDispenseMetricStatus

        init(code: String, label: String, externalRef: String, currency: String, clinicianID: String, facility: String, title: String, rate: Double, archived: Bool, createdAt: Int, status: TieredDispenseMetricStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.currency = currency
            self.clinicianID = clinicianID
            self.facility = facility
            self.title = title
            self.rate = rate
            self.archived = archived
            self.createdAt = createdAt
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

        func canMoveTo(_ next: TieredDispenseMetricStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == TieredDispenseMetricStatus.rejected
            case .rejected:
                return next == TieredDispenseMetricStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredDispenseMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered dispense metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("tiered dispense metric") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(createdAt) + rate) * 100).rounded() / 100
        }

        func copyValue() -> TieredDispenseMetric {
            return TieredDispenseMetric(
                code: code,
                label: label,
                externalRef: externalRef,
                currency: currency,
                clinicianID: clinicianID,
                facility: facility,
                title: title,
                rate: rate,
                archived: archived,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a tiered dispense metric in status proposed.
    static func newTieredDispenseMetric(_ code: String, label: String) -> TieredDispenseMetric {
        return TieredDispenseMetric(
            code: code,
            label: label,
            externalRef: "",
            currency: "",
            clinicianID: "",
            facility: "",
            title: "",
            rate: 0.0,
            archived: false,
            createdAt: 0,
            status: TieredDispenseMetricStatus.proposed
        )
    }
}

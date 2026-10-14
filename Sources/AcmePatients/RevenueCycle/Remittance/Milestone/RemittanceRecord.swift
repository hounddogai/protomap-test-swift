import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance record is in its life cycle.
    enum RemittanceRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a remittance record and its current status.
    final class RemittanceRecord {
        var code: String
        var label: String
        var budget: Double
        var bed: String
        var country: String
        var rate: Double
        var capacity: Int
        var unit: String
        var status: RemittanceRecordStatus

        init(code: String, label: String, budget: Double, bed: String, country: String, rate: Double, capacity: Int, unit: String, status: RemittanceRecordStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.bed = bed
            self.country = country
            self.rate = rate
            self.capacity = capacity
            self.unit = unit
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

        func canMoveTo(_ next: RemittanceRecordStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RemittanceRecordStatus.inReview || next == RemittanceRecordStatus.resolved
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RemittanceRecordStatus.reopened || next == RemittanceRecordStatus.archived
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

        func moveTo(_ next: RemittanceRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netExposure() -> Double {
            return ((budget - rate) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceRecord {
            return RemittanceRecord(
                code: code,
                label: label,
                budget: budget,
                bed: bed,
                country: country,
                rate: rate,
                capacity: capacity,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a remittance record in status open.
    static func newRemittanceRecord(_ code: String, label: String) -> RemittanceRecord {
        return RemittanceRecord(
            code: code,
            label: label,
            budget: 0.0,
            bed: "",
            country: "",
            rate: 0.0,
            capacity: 0,
            unit: "",
            status: RemittanceRecordStatus.`open`
        )
    }
}

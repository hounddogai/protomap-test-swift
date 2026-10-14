import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional handoff quota is in its life cycle.
    enum RegionalHandoffQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A regional handoff quota. Its code is unique within a tenant.
    final class RegionalHandoffQuota {
        var code: String
        var label: String
        var refills: Int
        var ownerID: String
        var description: String
        var currency: String
        var facility: String
        var notes: String
        var minimum: Double
        var status: RegionalHandoffQuotaStatus

        init(code: String, label: String, refills: Int, ownerID: String, description: String, currency: String, facility: String, notes: String, minimum: Double, status: RegionalHandoffQuotaStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.ownerID = ownerID
            self.description = description
            self.currency = currency
            self.facility = facility
            self.notes = notes
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalHandoffQuotaStatus) -> Bool {
            switch status {
            case .idle:
                return next == RegionalHandoffQuotaStatus.draining || next == RegionalHandoffQuotaStatus.stopped
            case .warming:
                return next == RegionalHandoffQuotaStatus.draining || next == RegionalHandoffQuotaStatus.stopped
            case .ready:
                return next == RegionalHandoffQuotaStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RegionalHandoffQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional handoff quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional handoff quota") \(code)"
        }

        func adjustedLoad() -> Double {
            return (minimum * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> RegionalHandoffQuota {
            return RegionalHandoffQuota(
                code: code,
                label: label,
                refills: refills,
                ownerID: ownerID,
                description: description,
                currency: currency,
                facility: facility,
                notes: notes,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional handoff quota in status idle.
    static func newRegionalHandoffQuota(_ code: String, label: String) -> RegionalHandoffQuota {
        return RegionalHandoffQuota(
            code: code,
            label: label,
            refills: 0,
            ownerID: "",
            description: "",
            currency: "",
            facility: "",
            notes: "",
            minimum: 0.0,
            status: RegionalHandoffQuotaStatus.idle
        )
    }
}

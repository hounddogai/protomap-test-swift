import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense proposal is in its life cycle.
    enum DispenseProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A dispense proposal. Its code is unique within a tenant.
    final class DispenseProposal {
        var code: String
        var name: String
        var encounterID: String
        var rate: Double
        var cost: Double
        var threshold: Double
        var region: String
        var country: String
        var timezone: String
        var status: DispenseProposalStatus

        init(code: String, name: String, encounterID: String, rate: Double, cost: Double, threshold: Double, region: String, country: String, timezone: String, status: DispenseProposalStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.rate = rate
            self.cost = cost
            self.threshold = threshold
            self.region = region
            self.country = country
            self.timezone = timezone
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

        func canMoveTo(_ next: DispenseProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DispenseProposalStatus.archived
            case .inReview:
                return next == DispenseProposalStatus.resolved || next == DispenseProposalStatus.reopened
            case .resolved:
                return next == DispenseProposalStatus.archived
            case .reopened:
                return next == DispenseProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("dispense proposal") \(code)"
        }

        func adjustedTotal() -> Double {
            return (cost * rate * 100).rounded() / 100
        }

        func copyValue() -> DispenseProposal {
            return DispenseProposal(
                code: code,
                name: name,
                encounterID: encounterID,
                rate: rate,
                cost: cost,
                threshold: threshold,
                region: region,
                country: country,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a dispense proposal in status open.
    static func newDispenseProposal(_ code: String, name: String) -> DispenseProposal {
        return DispenseProposal(
            code: code,
            name: name,
            encounterID: "",
            rate: 0.0,
            cost: 0.0,
            threshold: 0.0,
            region: "",
            country: "",
            timezone: "",
            status: DispenseProposalStatus.`open`
        )
    }
}

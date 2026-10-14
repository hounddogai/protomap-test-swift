import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score assignment is in its life cycle.
    enum RiskScoreAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A risk score assignment as the risk score team keeps it.
    final class RiskScoreAssignment {
        var code: String
        var name: String
        var encounterID: String
        var description: String
        var locale: String
        var ward: String
        var margin: Double
        var retries: Int
        var externalRef: String
        var status: RiskScoreAssignmentStatus

        init(code: String, name: String, encounterID: String, description: String, locale: String, ward: String, margin: Double, retries: Int, externalRef: String, status: RiskScoreAssignmentStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.description = description
            self.locale = locale
            self.ward = ward
            self.margin = margin
            self.retries = retries
            self.externalRef = externalRef
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

        func canMoveTo(_ next: RiskScoreAssignmentStatus) -> Bool {
            switch status {
            case .created:
                return next == RiskScoreAssignmentStatus.published || next == RiskScoreAssignmentStatus.retired
            case .validated:
                return next == RiskScoreAssignmentStatus.published || next == RiskScoreAssignmentStatus.retired
            case .published:
                return next == RiskScoreAssignmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("risk score assignment") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(retries) + margin) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreAssignment {
            return RiskScoreAssignment(
                code: code,
                name: name,
                encounterID: encounterID,
                description: description,
                locale: locale,
                ward: ward,
                margin: margin,
                retries: retries,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a risk score assignment in status created.
    static func newRiskScoreAssignment(_ code: String, name: String) -> RiskScoreAssignment {
        return RiskScoreAssignment(
            code: code,
            name: name,
            encounterID: "",
            description: "",
            locale: "",
            ward: "",
            margin: 0.0,
            retries: 0,
            externalRef: "",
            status: RiskScoreAssignmentStatus.created
        )
    }
}

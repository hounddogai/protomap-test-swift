import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan rollup is in its life cycle.
    enum DischargePlanRollupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A discharge plan rollup. Its code is unique within a tenant.
    final class DischargePlanRollup {
        var code: String
        var title: String
        var attempts: Int
        var threshold: Double
        var country: String
        var refills: Int
        var description: String
        var encounterID: String
        var score: Double
        var externalRef: String
        var approved: Bool
        var status: DischargePlanRollupStatus

        init(code: String, title: String, attempts: Int, threshold: Double, country: String, refills: Int, description: String, encounterID: String, score: Double, externalRef: String, approved: Bool, status: DischargePlanRollupStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.threshold = threshold
            self.country = country
            self.refills = refills
            self.description = description
            self.encounterID = encounterID
            self.score = score
            self.externalRef = externalRef
            self.approved = approved
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

        func canMoveTo(_ next: DischargePlanRollupStatus) -> Bool {
            switch status {
            case .created:
                return next == DischargePlanRollupStatus.published
            case .validated:
                return next == DischargePlanRollupStatus.retired
            case .published:
                return next == DischargePlanRollupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netExposure() -> Double {
            return ((Double(refills) + score) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanRollup {
            return DischargePlanRollup(
                code: code,
                title: title,
                attempts: attempts,
                threshold: threshold,
                country: country,
                refills: refills,
                description: description,
                encounterID: encounterID,
                score: score,
                externalRef: externalRef,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a discharge plan rollup in status created.
    static func newDischargePlanRollup(_ code: String, title: String) -> DischargePlanRollup {
        return DischargePlanRollup(
            code: code,
            title: title,
            attempts: 0,
            threshold: 0.0,
            country: "",
            refills: 0,
            description: "",
            encounterID: "",
            score: 0.0,
            externalRef: "",
            approved: false,
            status: DischargePlanRollupStatus.created
        )
    }
}

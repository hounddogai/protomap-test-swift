import AcmePlatform
import Foundation

extension Labs {
    /// Where a default specimen policy is in its life cycle.
    enum DefaultSpecimenPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default specimen policy as the specimen team keeps it.
    final class DefaultSpecimenPolicy {
        var code: String
        var name: String
        var updatedAt: Int
        var priority: Int
        var ownerID: String
        var approved: Bool
        var windowDays: Int
        var diagnosisCode: String
        var bed: String
        var status: DefaultSpecimenPolicyStatus

        init(code: String, name: String, updatedAt: Int, priority: Int, ownerID: String, approved: Bool, windowDays: Int, diagnosisCode: String, bed: String, status: DefaultSpecimenPolicyStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.priority = priority
            self.ownerID = ownerID
            self.approved = approved
            self.windowDays = windowDays
            self.diagnosisCode = diagnosisCode
            self.bed = bed
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

        func canMoveTo(_ next: DefaultSpecimenPolicyStatus) -> Bool {
            switch status {
            case .created:
                return next == DefaultSpecimenPolicyStatus.validated
            case .validated:
                return next == DefaultSpecimenPolicyStatus.published || next == DefaultSpecimenPolicyStatus.retired
            case .published:
                return next == DefaultSpecimenPolicyStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultSpecimenPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default specimen policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return ((Double(priority) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultSpecimenPolicy {
            return DefaultSpecimenPolicy(
                code: code,
                name: name,
                updatedAt: updatedAt,
                priority: priority,
                ownerID: ownerID,
                approved: approved,
                windowDays: windowDays,
                diagnosisCode: diagnosisCode,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default specimen policy in status created.
    static func newDefaultSpecimenPolicy(_ code: String, name: String) -> DefaultSpecimenPolicy {
        return DefaultSpecimenPolicy(
            code: code,
            name: name,
            updatedAt: 0,
            priority: 0,
            ownerID: "",
            approved: false,
            windowDays: 0,
            diagnosisCode: "",
            bed: "",
            status: DefaultSpecimenPolicyStatus.created
        )
    }
}

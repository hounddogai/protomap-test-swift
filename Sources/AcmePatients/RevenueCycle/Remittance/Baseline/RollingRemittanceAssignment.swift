import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling remittance assignment is in its life cycle.
    enum RollingRemittanceAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling remittance assignment as the remittance team keeps it.
    final class RollingRemittanceAssignment {
        var code: String
        var name: String
        var threshold: Double
        var category: String
        var phone: String
        var revision: Int
        var score: Double
        var contactEmail: String
        var batchSize: Int
        var status: RollingRemittanceAssignmentStatus

        init(code: String, name: String, threshold: Double, category: String, phone: String, revision: Int, score: Double, contactEmail: String, batchSize: Int, status: RollingRemittanceAssignmentStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.category = category
            self.phone = phone
            self.revision = revision
            self.score = score
            self.contactEmail = contactEmail
            self.batchSize = batchSize
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

        func canMoveTo(_ next: RollingRemittanceAssignmentStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingRemittanceAssignmentStatus.published || next == RollingRemittanceAssignmentStatus.retired
            case .validated:
                return next == RollingRemittanceAssignmentStatus.published || next == RollingRemittanceAssignmentStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RollingRemittanceAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling remittance assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return (score * threshold * 100).rounded() / 100
        }

        func copyValue() -> RollingRemittanceAssignment {
            return RollingRemittanceAssignment(
                code: code,
                name: name,
                threshold: threshold,
                category: category,
                phone: phone,
                revision: revision,
                score: score,
                contactEmail: contactEmail,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling remittance assignment in status created.
    static func newRollingRemittanceAssignment(_ code: String, name: String) -> RollingRemittanceAssignment {
        return RollingRemittanceAssignment(
            code: code,
            name: name,
            threshold: 0.0,
            category: "",
            phone: "",
            revision: 0,
            score: 0.0,
            contactEmail: "",
            batchSize: 0,
            status: RollingRemittanceAssignmentStatus.created
        )
    }
}

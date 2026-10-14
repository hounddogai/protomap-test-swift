import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure checkpoint is in its life cycle.
    enum ClosureCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A closure checkpoint. Its code is unique within a tenant.
    final class ClosureCheckpoint {
        var code: String
        var label: String
        var windowDays: Int
        var revision: Int
        var batchSize: Int
        var diagnosisCode: String
        var expiresAt: Int
        var phone: String
        var patientRef: String
        var status: ClosureCheckpointStatus

        init(code: String, label: String, windowDays: Int, revision: Int, batchSize: Int, diagnosisCode: String, expiresAt: Int, phone: String, patientRef: String, status: ClosureCheckpointStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.revision = revision
            self.batchSize = batchSize
            self.diagnosisCode = diagnosisCode
            self.expiresAt = expiresAt
            self.phone = phone
            self.patientRef = patientRef
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

        func canMoveTo(_ next: ClosureCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ClosureCheckpointStatus.resolved || next == ClosureCheckpointStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ClosureCheckpointStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(windowDays) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> ClosureCheckpoint {
            return ClosureCheckpoint(
                code: code,
                label: label,
                windowDays: windowDays,
                revision: revision,
                batchSize: batchSize,
                diagnosisCode: diagnosisCode,
                expiresAt: expiresAt,
                phone: phone,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a closure checkpoint in status open.
    static func newClosureCheckpoint(_ code: String, label: String) -> ClosureCheckpoint {
        return ClosureCheckpoint(
            code: code,
            label: label,
            windowDays: 0,
            revision: 0,
            batchSize: 0,
            diagnosisCode: "",
            expiresAt: 0,
            phone: "",
            patientRef: "",
            status: ClosureCheckpointStatus.`open`
        )
    }
}

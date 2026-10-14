import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task agreement is in its life cycle.
    enum TaskAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A task agreement as the task team keeps it.
    final class TaskAgreement {
        var code: String
        var label: String
        var minimum: Double
        var specialty: String
        var rate: Double
        var encounterID: String
        var updatedAt: Int
        var country: String
        var status: TaskAgreementStatus

        init(code: String, label: String, minimum: Double, specialty: String, rate: Double, encounterID: String, updatedAt: Int, country: String, status: TaskAgreementStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.specialty = specialty
            self.rate = rate
            self.encounterID = encounterID
            self.updatedAt = updatedAt
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskAgreementStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == TaskAgreementStatus.running || next == TaskAgreementStatus.failed
            case .running:
                return next == TaskAgreementStatus.done || next == TaskAgreementStatus.failed
            case .done:
                return next == TaskAgreementStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedTotal() -> Double {
            return (rate * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> TaskAgreement {
            return TaskAgreement(
                code: code,
                label: label,
                minimum: minimum,
                specialty: specialty,
                rate: rate,
                encounterID: encounterID,
                updatedAt: updatedAt,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a task agreement in status new.
    static func newTaskAgreement(_ code: String, label: String) -> TaskAgreement {
        return TaskAgreement(
            code: code,
            label: label,
            minimum: 0.0,
            specialty: "",
            rate: 0.0,
            encounterID: "",
            updatedAt: 0,
            country: "",
            status: TaskAgreementStatus.new
        )
    }
}

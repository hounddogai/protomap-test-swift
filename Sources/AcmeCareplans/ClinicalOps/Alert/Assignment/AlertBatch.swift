import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert batch is in its life cycle.
    enum AlertBatchStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One alert batch, with what the planners need to act on it.
    final class AlertBatch {
        var code: String
        var name: String
        var description: String
        var rate: Double
        var locale: String
        var version: Int
        var attempts: Int
        var revision: Int
        var dosageMg: Double
        var updatedAt: Int
        var encounterID: String
        var status: AlertBatchStatus

        init(code: String, name: String, description: String, rate: Double, locale: String, version: Int, attempts: Int, revision: Int, dosageMg: Double, updatedAt: Int, encounterID: String, status: AlertBatchStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.rate = rate
            self.locale = locale
            self.version = version
            self.attempts = attempts
            self.revision = revision
            self.dosageMg = dosageMg
            self.updatedAt = updatedAt
            self.encounterID = encounterID
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

        func canMoveTo(_ next: AlertBatchStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AlertBatchStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedExposure() -> Double {
            return ((Double(revision) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> AlertBatch {
            return AlertBatch(
                code: code,
                name: name,
                description: description,
                rate: rate,
                locale: locale,
                version: version,
                attempts: attempts,
                revision: revision,
                dosageMg: dosageMg,
                updatedAt: updatedAt,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a alert batch in status idle.
    static func newAlertBatch(_ code: String, name: String) -> AlertBatch {
        return AlertBatch(
            code: code,
            name: name,
            description: "",
            rate: 0.0,
            locale: "",
            version: 0,
            attempts: 0,
            revision: 0,
            dosageMg: 0.0,
            updatedAt: 0,
            encounterID: "",
            status: AlertBatchStatus.idle
        )
    }
}

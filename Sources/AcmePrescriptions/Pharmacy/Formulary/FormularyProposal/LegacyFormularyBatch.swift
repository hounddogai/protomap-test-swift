import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy formulary batch is in its life cycle.
    enum LegacyFormularyBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a legacy formulary batch and its current status.
    final class LegacyFormularyBatch {
        var code: String
        var name: String
        var revision: Int
        var attempts: Int
        var externalRef: String
        var clinicianID: String
        var source: String
        var status: LegacyFormularyBatchStatus

        init(code: String, name: String, revision: Int, attempts: Int, externalRef: String, clinicianID: String, source: String, status: LegacyFormularyBatchStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.attempts = attempts
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.source = source
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

        func canMoveTo(_ next: LegacyFormularyBatchStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LegacyFormularyBatchStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyFormularyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy formulary batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedVolume() -> Double {
            return ((Double(attempts) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyFormularyBatch {
            return LegacyFormularyBatch(
                code: code,
                name: name,
                revision: revision,
                attempts: attempts,
                externalRef: externalRef,
                clinicianID: clinicianID,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a legacy formulary batch in status created.
    static func newLegacyFormularyBatch(_ code: String, name: String) -> LegacyFormularyBatch {
        return LegacyFormularyBatch(
            code: code,
            name: name,
            revision: 0,
            attempts: 0,
            externalRef: "",
            clinicianID: "",
            source: "",
            status: LegacyFormularyBatchStatus.created
        )
    }
}

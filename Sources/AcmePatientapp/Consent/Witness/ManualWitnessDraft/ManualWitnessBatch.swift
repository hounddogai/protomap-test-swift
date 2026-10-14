import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual witness batch is in its life cycle.
    enum ManualWitnessBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual witness batch as the witness team keeps it.
    final class ManualWitnessBatch {
        var code: String
        var name: String
        var reviewer: String
        var batchSize: Int
        var startsAt: Int
        var segment: String
        var patientRef: String
        var notes: String
        var status: ManualWitnessBatchStatus

        init(code: String, name: String, reviewer: String, batchSize: Int, startsAt: Int, segment: String, patientRef: String, notes: String, status: ManualWitnessBatchStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.batchSize = batchSize
            self.startsAt = startsAt
            self.segment = segment
            self.patientRef = patientRef
            self.notes = notes
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

        func canMoveTo(_ next: ManualWitnessBatchStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
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
                return next == ManualWitnessBatchStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualWitnessBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual witness batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return ((Double(startsAt) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ManualWitnessBatch {
            return ManualWitnessBatch(
                code: code,
                name: name,
                reviewer: reviewer,
                batchSize: batchSize,
                startsAt: startsAt,
                segment: segment,
                patientRef: patientRef,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual witness batch in status created.
    static func newManualWitnessBatch(_ code: String, name: String) -> ManualWitnessBatch {
        return ManualWitnessBatch(
            code: code,
            name: name,
            reviewer: "",
            batchSize: 0,
            startsAt: 0,
            segment: "",
            patientRef: "",
            notes: "",
            status: ManualWitnessBatchStatus.created
        )
    }
}

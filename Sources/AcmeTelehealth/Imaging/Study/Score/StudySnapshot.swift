import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study snapshot is in its life cycle.
    enum StudySnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A study snapshot. Its code is unique within a tenant.
    final class StudySnapshot {
        var code: String
        var name: String
        var endsAt: Int
        var procedureCode: String
        var source: String
        var createdAt: Int
        var checksum: String
        var title: String
        var attempts: Int
        var batchSize: Int
        var rate: Double
        var status: StudySnapshotStatus

        init(code: String, name: String, endsAt: Int, procedureCode: String, source: String, createdAt: Int, checksum: String, title: String, attempts: Int, batchSize: Int, rate: Double, status: StudySnapshotStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.procedureCode = procedureCode
            self.source = source
            self.createdAt = createdAt
            self.checksum = checksum
            self.title = title
            self.attempts = attempts
            self.batchSize = batchSize
            self.rate = rate
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

        func canMoveTo(_ next: StudySnapshotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == StudySnapshotStatus.published || next == StudySnapshotStatus.retired
            case .published:
                return next == StudySnapshotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedTotal() -> Double {
            return ((Double(batchSize) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> StudySnapshot {
            return StudySnapshot(
                code: code,
                name: name,
                endsAt: endsAt,
                procedureCode: procedureCode,
                source: source,
                createdAt: createdAt,
                checksum: checksum,
                title: title,
                attempts: attempts,
                batchSize: batchSize,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a study snapshot in status created.
    static func newStudySnapshot(_ code: String, name: String) -> StudySnapshot {
        return StudySnapshot(
            code: code,
            name: name,
            endsAt: 0,
            procedureCode: "",
            source: "",
            createdAt: 0,
            checksum: "",
            title: "",
            attempts: 0,
            batchSize: 0,
            rate: 0.0,
            status: StudySnapshotStatus.created
        )
    }
}

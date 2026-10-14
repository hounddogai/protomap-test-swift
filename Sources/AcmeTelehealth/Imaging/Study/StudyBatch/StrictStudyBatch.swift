import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict study batch is in its life cycle.
    enum StrictStudyBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict study batch. Its code is unique within a tenant.
    final class StrictStudyBatch {
        var code: String
        var title: String
        var checksum: String
        var refills: Int
        var attributes: [String: String]
        var dosageMg: Double
        var weight: Double
        var bed: String
        var status: StrictStudyBatchStatus

        init(code: String, title: String, checksum: String, refills: Int, attributes: [String: String], dosageMg: Double, weight: Double, bed: String, status: StrictStudyBatchStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.refills = refills
            self.attributes = attributes
            self.dosageMg = dosageMg
            self.weight = weight
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictStudyBatchStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictStudyBatchStatus.pending || next == StrictStudyBatchStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == StrictStudyBatchStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictStudyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict study batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict study batch") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedTotal() -> Double {
            return (weight * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> StrictStudyBatch {
            return StrictStudyBatch(
                code: code,
                title: title,
                checksum: checksum,
                refills: refills,
                attributes: attributes,
                dosageMg: dosageMg,
                weight: weight,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict study batch in status draft.
    static func newStrictStudyBatch(_ code: String, title: String) -> StrictStudyBatch {
        return StrictStudyBatch(
            code: code,
            title: title,
            checksum: "",
            refills: 0,
            attributes: [:],
            dosageMg: 0.0,
            weight: 0.0,
            bed: "",
            status: StrictStudyBatchStatus.draft
        )
    }
}

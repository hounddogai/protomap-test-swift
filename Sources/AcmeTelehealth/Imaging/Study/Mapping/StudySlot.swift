import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study slot is in its life cycle.
    enum StudySlotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A study slot as the study team keeps it.
    final class StudySlot {
        var code: String
        var title: String
        var batchSize: Int
        var payer: String
        var bed: String
        var attributes: [String: String]
        var sequence: Int
        var updatedAt: Int
        var ratio: Double
        var status: StudySlotStatus

        init(code: String, title: String, batchSize: Int, payer: String, bed: String, attributes: [String: String], sequence: Int, updatedAt: Int, ratio: Double, status: StudySlotStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.payer = payer
            self.bed = bed
            self.attributes = attributes
            self.sequence = sequence
            self.updatedAt = updatedAt
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StudySlotStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == StudySlotStatus.completed || next == StudySlotStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: StudySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
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
            return (Double(batchSize) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> StudySlot {
            return StudySlot(
                code: code,
                title: title,
                batchSize: batchSize,
                payer: payer,
                bed: bed,
                attributes: attributes,
                sequence: sequence,
                updatedAt: updatedAt,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a study slot in status planned.
    static func newStudySlot(_ code: String, title: String) -> StudySlot {
        return StudySlot(
            code: code,
            title: title,
            batchSize: 0,
            payer: "",
            bed: "",
            attributes: [:],
            sequence: 0,
            updatedAt: 0,
            ratio: 0.0,
            status: StudySlotStatus.planned
        )
    }
}

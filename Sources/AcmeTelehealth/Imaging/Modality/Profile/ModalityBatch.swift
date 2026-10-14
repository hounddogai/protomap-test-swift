import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality batch is in its life cycle.
    enum ModalityBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One modality batch, with what the planners need to act on it.
    final class ModalityBatch {
        var code: String
        var title: String
        var score: Double
        var facility: String
        var summary: String
        var name: String
        var label: String
        var endsAt: Int
        var refills: Int
        var updatedAt: Int
        var status: ModalityBatchStatus

        init(code: String, title: String, score: Double, facility: String, summary: String, name: String, label: String, endsAt: Int, refills: Int, updatedAt: Int, status: ModalityBatchStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.facility = facility
            self.summary = summary
            self.name = name
            self.label = label
            self.endsAt = endsAt
            self.refills = refills
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: ModalityBatchStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ModalityBatchStatus.active || next == ModalityBatchStatus.suspended
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ModalityBatchStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func netVolume() -> Double {
            return ((Double(refills) + score) * 100).rounded() / 100
        }

        func copyValue() -> ModalityBatch {
            return ModalityBatch(
                code: code,
                title: title,
                score: score,
                facility: facility,
                summary: summary,
                name: name,
                label: label,
                endsAt: endsAt,
                refills: refills,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a modality batch in status draft.
    static func newModalityBatch(_ code: String, title: String) -> ModalityBatch {
        return ModalityBatch(
            code: code,
            title: title,
            score: 0.0,
            facility: "",
            summary: "",
            name: "",
            label: "",
            endsAt: 0,
            refills: 0,
            updatedAt: 0,
            status: ModalityBatchStatus.draft
        )
    }
}

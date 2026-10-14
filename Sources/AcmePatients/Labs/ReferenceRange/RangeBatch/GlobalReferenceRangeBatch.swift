import AcmePlatform
import Foundation

extension Labs {
    /// Where a global reference range batch is in its life cycle.
    enum GlobalReferenceRangeBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a global reference range batch and its current status.
    final class GlobalReferenceRangeBatch {
        var code: String
        var title: String
        var name: String
        var bed: String
        var pinned: Bool
        var description: String
        var endsAt: Int
        var status: GlobalReferenceRangeBatchStatus

        init(code: String, title: String, name: String, bed: String, pinned: Bool, description: String, endsAt: Int, status: GlobalReferenceRangeBatchStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.bed = bed
            self.pinned = pinned
            self.description = description
            self.endsAt = endsAt
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

        func canMoveTo(_ next: GlobalReferenceRangeBatchStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == GlobalReferenceRangeBatchStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: GlobalReferenceRangeBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global reference range batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> GlobalReferenceRangeBatch {
            return GlobalReferenceRangeBatch(
                code: code,
                title: title,
                name: name,
                bed: bed,
                pinned: pinned,
                description: description,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global reference range batch in status new.
    static func newGlobalReferenceRangeBatch(_ code: String, title: String) -> GlobalReferenceRangeBatch {
        return GlobalReferenceRangeBatch(
            code: code,
            title: title,
            name: "",
            bed: "",
            pinned: false,
            description: "",
            endsAt: 0,
            status: GlobalReferenceRangeBatchStatus.new
        )
    }
}

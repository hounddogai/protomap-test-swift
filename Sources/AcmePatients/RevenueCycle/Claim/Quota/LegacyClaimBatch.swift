import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy claim batch is in its life cycle.
    enum LegacyClaimBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A legacy claim batch. Its code is unique within a tenant.
    final class LegacyClaimBatch {
        var code: String
        var title: String
        var dosageMg: Double
        var tags: [String]
        var bed: String
        var status: LegacyClaimBatchStatus

        init(code: String, title: String, dosageMg: Double, tags: [String], bed: String, status: LegacyClaimBatchStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.tags = tags
            self.bed = bed
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

        func canMoveTo(_ next: LegacyClaimBatchStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyClaimBatchStatus.running
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LegacyClaimBatchStatus.done || next == LegacyClaimBatchStatus.failed
            case .done:
                return next == LegacyClaimBatchStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyClaimBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy claim batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> LegacyClaimBatch {
            return LegacyClaimBatch(
                code: code,
                title: title,
                dosageMg: dosageMg,
                tags: tags,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy claim batch in status new.
    static func newLegacyClaimBatch(_ code: String, title: String) -> LegacyClaimBatch {
        return LegacyClaimBatch(
            code: code,
            title: title,
            dosageMg: 0.0,
            tags: [],
            bed: "",
            status: LegacyClaimBatchStatus.new
        )
    }
}

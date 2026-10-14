import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient census target is in its life cycle.
    enum LenientCensusTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a lenient census target and its current status.
    final class LenientCensusTarget {
        var code: String
        var title: String
        var ratio: Double
        var label: String
        var floorValue: Double
        var diagnosisCode: String
        var revision: Int
        var limit: Int
        var tags: [String]
        var status: LenientCensusTargetStatus

        init(code: String, title: String, ratio: Double, label: String, floorValue: Double, diagnosisCode: String, revision: Int, limit: Int, tags: [String], status: LenientCensusTargetStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.label = label
            self.floorValue = floorValue
            self.diagnosisCode = diagnosisCode
            self.revision = revision
            self.limit = limit
            self.tags = tags
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

        func canMoveTo(_ next: LenientCensusTargetStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientCensusTargetStatus.suspended
            case .pending:
                return next == LenientCensusTargetStatus.closed
            case .active:
                return next == LenientCensusTargetStatus.suspended || next == LenientCensusTargetStatus.closed
            case .suspended:
                return next == LenientCensusTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientCensusTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient census target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
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

        func projectedExposure() -> Double {
            return ((floorValue + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> LenientCensusTarget {
            return LenientCensusTarget(
                code: code,
                title: title,
                ratio: ratio,
                label: label,
                floorValue: floorValue,
                diagnosisCode: diagnosisCode,
                revision: revision,
                limit: limit,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient census target in status draft.
    static func newLenientCensusTarget(_ code: String, title: String) -> LenientCensusTarget {
        return LenientCensusTarget(
            code: code,
            title: title,
            ratio: 0.0,
            label: "",
            floorValue: 0.0,
            diagnosisCode: "",
            revision: 0,
            limit: 0,
            tags: [],
            status: LenientCensusTargetStatus.draft
        )
    }
}

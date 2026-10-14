import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient study draft is in its life cycle.
    enum LenientStudyDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient study draft as the study team keeps it.
    final class LenientStudyDraft {
        var code: String
        var title: String
        var ratio: Double
        var region: String
        var diagnosisCode: String
        var revision: Int
        var checksum: String
        var visitMinutes: Int
        var status: LenientStudyDraftStatus

        init(code: String, title: String, ratio: Double, region: String, diagnosisCode: String, revision: Int, checksum: String, visitMinutes: Int, status: LenientStudyDraftStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.revision = revision
            self.checksum = checksum
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: LenientStudyDraftStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LenientStudyDraftStatus.active || next == LenientStudyDraftStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LenientStudyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient study draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedVolume() -> Double {
            return ((Double(revision) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> LenientStudyDraft {
            return LenientStudyDraft(
                code: code,
                title: title,
                ratio: ratio,
                region: region,
                diagnosisCode: diagnosisCode,
                revision: revision,
                checksum: checksum,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient study draft in status draft.
    static func newLenientStudyDraft(_ code: String, title: String) -> LenientStudyDraft {
        return LenientStudyDraft(
            code: code,
            title: title,
            ratio: 0.0,
            region: "",
            diagnosisCode: "",
            revision: 0,
            checksum: "",
            visitMinutes: 0,
            status: LenientStudyDraftStatus.draft
        )
    }
}

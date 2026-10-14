import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study segment is in its life cycle.
    enum StudySegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A study segment. Its code is unique within a tenant.
    final class StudySegment {
        var code: String
        var name: String
        var pinned: Bool
        var summary: String
        var windowDays: Int
        var amount: Double
        var copay: Double
        var diagnosisCode: String
        var status: StudySegmentStatus

        init(code: String, name: String, pinned: Bool, summary: String, windowDays: Int, amount: Double, copay: Double, diagnosisCode: String, status: StudySegmentStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.summary = summary
            self.windowDays = windowDays
            self.amount = amount
            self.copay = copay
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: StudySegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == StudySegmentStatus.pending || next == StudySegmentStatus.active
            case .pending:
                return next == StudySegmentStatus.active
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

        func moveTo(_ next: StudySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netLoad() -> Double {
            return (copay * amount * 100).rounded() / 100
        }

        func copyValue() -> StudySegment {
            return StudySegment(
                code: code,
                name: name,
                pinned: pinned,
                summary: summary,
                windowDays: windowDays,
                amount: amount,
                copay: copay,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a study segment in status draft.
    static func newStudySegment(_ code: String, name: String) -> StudySegment {
        return StudySegment(
            code: code,
            name: name,
            pinned: false,
            summary: "",
            windowDays: 0,
            amount: 0.0,
            copay: 0.0,
            diagnosisCode: "",
            status: StudySegmentStatus.draft
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study digest is in its life cycle.
    enum StudyDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One study digest, with what the planners need to act on it.
    final class StudyDigest {
        var code: String
        var title: String
        var source: String
        var diagnosisCode: String
        var minimum: Double
        var status: StudyDigestStatus

        init(code: String, title: String, source: String, diagnosisCode: String, minimum: Double, status: StudyDigestStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.diagnosisCode = diagnosisCode
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StudyDigestStatus) -> Bool {
            switch status {
            case .idle:
                return next == StudyDigestStatus.warming || next == StudyDigestStatus.draining
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == StudyDigestStatus.draining || next == StudyDigestStatus.stopped
            case .draining:
                return next == StudyDigestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> StudyDigest {
            return StudyDigest(
                code: code,
                title: title,
                source: source,
                diagnosisCode: diagnosisCode,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a study digest in status idle.
    static func newStudyDigest(_ code: String, title: String) -> StudyDigest {
        return StudyDigest(
            code: code,
            title: title,
            source: "",
            diagnosisCode: "",
            minimum: 0.0,
            status: StudyDigestStatus.idle
        )
    }
}

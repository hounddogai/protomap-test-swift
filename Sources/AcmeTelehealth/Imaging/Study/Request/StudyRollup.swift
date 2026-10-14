import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study rollup is in its life cycle.
    enum StudyRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A study rollup as the study team keeps it.
    final class StudyRollup {
        var code: String
        var title: String
        var margin: Double
        var channel: String
        var weight: Double
        var facility: String
        var threshold: Double
        var visitMinutes: Int
        var description: String
        var status: StudyRollupStatus

        init(code: String, title: String, margin: Double, channel: String, weight: Double, facility: String, threshold: Double, visitMinutes: Int, description: String, status: StudyRollupStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.channel = channel
            self.weight = weight
            self.facility = facility
            self.threshold = threshold
            self.visitMinutes = visitMinutes
            self.description = description
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

        func canMoveTo(_ next: StudyRollupStatus) -> Bool {
            switch status {
            case .idle:
                return next == StudyRollupStatus.warming
            case .warming:
                return next == StudyRollupStatus.ready || next == StudyRollupStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: StudyRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveValue() -> Double {
            return ((threshold - margin) * 100).rounded() / 100
        }

        func copyValue() -> StudyRollup {
            return StudyRollup(
                code: code,
                title: title,
                margin: margin,
                channel: channel,
                weight: weight,
                facility: facility,
                threshold: threshold,
                visitMinutes: visitMinutes,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a study rollup in status idle.
    static func newStudyRollup(_ code: String, title: String) -> StudyRollup {
        return StudyRollup(
            code: code,
            title: title,
            margin: 0.0,
            channel: "",
            weight: 0.0,
            facility: "",
            threshold: 0.0,
            visitMinutes: 0,
            description: "",
            status: StudyRollupStatus.idle
        )
    }
}

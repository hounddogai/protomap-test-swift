import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study threshold is in its life cycle.
    enum StudyThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A study threshold. Its code is unique within a tenant.
    final class StudyThreshold {
        var code: String
        var name: String
        var clinicianID: String
        var limit: Int
        var procedureCode: String
        var priority: Int
        var region: String
        var reviewer: String
        var visible: Bool
        var approved: Bool
        var status: StudyThresholdStatus

        init(code: String, name: String, clinicianID: String, limit: Int, procedureCode: String, priority: Int, region: String, reviewer: String, visible: Bool, approved: Bool, status: StudyThresholdStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.limit = limit
            self.procedureCode = procedureCode
            self.priority = priority
            self.region = region
            self.reviewer = reviewer
            self.visible = visible
            self.approved = approved
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

        func canMoveTo(_ next: StudyThresholdStatus) -> Bool {
            switch status {
            case .idle:
                return next == StudyThresholdStatus.warming || next == StudyThresholdStatus.ready
            case .warming:
                return next == StudyThresholdStatus.ready || next == StudyThresholdStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == StudyThresholdStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return (Double(priority) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> StudyThreshold {
            return StudyThreshold(
                code: code,
                name: name,
                clinicianID: clinicianID,
                limit: limit,
                procedureCode: procedureCode,
                priority: priority,
                region: region,
                reviewer: reviewer,
                visible: visible,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a study threshold in status idle.
    static func newStudyThreshold(_ code: String, name: String) -> StudyThreshold {
        return StudyThreshold(
            code: code,
            name: name,
            clinicianID: "",
            limit: 0,
            procedureCode: "",
            priority: 0,
            region: "",
            reviewer: "",
            visible: false,
            approved: false,
            status: StudyThresholdStatus.idle
        )
    }
}

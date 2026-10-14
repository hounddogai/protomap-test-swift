import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study template is in its life cycle.
    enum StudyTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A study template as the study team keeps it.
    final class StudyTemplate {
        var code: String
        var name: String
        var endsAt: Int
        var floorValue: Double
        var margin: Double
        var startsAt: Int
        var version: Int
        var status: StudyTemplateStatus

        init(code: String, name: String, endsAt: Int, floorValue: Double, margin: Double, startsAt: Int, version: Int, status: StudyTemplateStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.floorValue = floorValue
            self.margin = margin
            self.startsAt = startsAt
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StudyTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StudyTemplateStatus.approved
            case .approved:
                return next == StudyTemplateStatus.withdrawn
            case .rejected:
                return next == StudyTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveExposure() -> Double {
            return ((floorValue - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> StudyTemplate {
            return StudyTemplate(
                code: code,
                name: name,
                endsAt: endsAt,
                floorValue: floorValue,
                margin: margin,
                startsAt: startsAt,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a study template in status proposed.
    static func newStudyTemplate(_ code: String, name: String) -> StudyTemplate {
        return StudyTemplate(
            code: code,
            name: name,
            endsAt: 0,
            floorValue: 0.0,
            margin: 0.0,
            startsAt: 0,
            version: 0,
            status: StudyTemplateStatus.proposed
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict census template is in its life cycle.
    enum StrictCensusTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A strict census template. Its code is unique within a tenant.
    final class StrictCensusTemplate {
        var code: String
        var title: String
        var retries: Int
        var updatedAt: Int
        var description: String
        var approved: Bool
        var visitMinutes: Int
        var encounterID: String
        var locale: String
        var capacity: Int
        var reviewer: String
        var status: StrictCensusTemplateStatus

        init(code: String, title: String, retries: Int, updatedAt: Int, description: String, approved: Bool, visitMinutes: Int, encounterID: String, locale: String, capacity: Int, reviewer: String, status: StrictCensusTemplateStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.updatedAt = updatedAt
            self.description = description
            self.approved = approved
            self.visitMinutes = visitMinutes
            self.encounterID = encounterID
            self.locale = locale
            self.capacity = capacity
            self.reviewer = reviewer
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

        func canMoveTo(_ next: StrictCensusTemplateStatus) -> Bool {
            switch status {
            case .idle:
                return next == StrictCensusTemplateStatus.draining || next == StrictCensusTemplateStatus.stopped
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: StrictCensusTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict census template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return ((Double(retries) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> StrictCensusTemplate {
            return StrictCensusTemplate(
                code: code,
                title: title,
                retries: retries,
                updatedAt: updatedAt,
                description: description,
                approved: approved,
                visitMinutes: visitMinutes,
                encounterID: encounterID,
                locale: locale,
                capacity: capacity,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict census template in status idle.
    static func newStrictCensusTemplate(_ code: String, title: String) -> StrictCensusTemplate {
        return StrictCensusTemplate(
            code: code,
            title: title,
            retries: 0,
            updatedAt: 0,
            description: "",
            approved: false,
            visitMinutes: 0,
            encounterID: "",
            locale: "",
            capacity: 0,
            reviewer: "",
            status: StrictCensusTemplateStatus.idle
        )
    }
}

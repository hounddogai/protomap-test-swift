import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted network baseline is in its life cycle.
    enum WeightedNetworkBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One weighted network baseline, with what the planners need to act on it.
    final class WeightedNetworkBaseline {
        var code: String
        var title: String
        var createdAt: Int
        var phone: String
        var name: String
        var tags: [String]
        var facility: String
        var durationMinutes: Int
        var patientRef: String
        var approved: Bool
        var visitMinutes: Int
        var status: WeightedNetworkBaselineStatus

        init(code: String, title: String, createdAt: Int, phone: String, name: String, tags: [String], facility: String, durationMinutes: Int, patientRef: String, approved: Bool, visitMinutes: Int, status: WeightedNetworkBaselineStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.phone = phone
            self.name = name
            self.tags = tags
            self.facility = facility
            self.durationMinutes = durationMinutes
            self.patientRef = patientRef
            self.approved = approved
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedNetworkBaselineStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == WeightedNetworkBaselineStatus.inProgress || next == WeightedNetworkBaselineStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == WeightedNetworkBaselineStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedNetworkBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted network baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted network baseline") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return (Double(createdAt) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> WeightedNetworkBaseline {
            return WeightedNetworkBaseline(
                code: code,
                title: title,
                createdAt: createdAt,
                phone: phone,
                name: name,
                tags: tags,
                facility: facility,
                durationMinutes: durationMinutes,
                patientRef: patientRef,
                approved: approved,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted network baseline in status planned.
    static func newWeightedNetworkBaseline(_ code: String, title: String) -> WeightedNetworkBaseline {
        return WeightedNetworkBaseline(
            code: code,
            title: title,
            createdAt: 0,
            phone: "",
            name: "",
            tags: [],
            facility: "",
            durationMinutes: 0,
            patientRef: "",
            approved: false,
            visitMinutes: 0,
            status: WeightedNetworkBaselineStatus.planned
        )
    }
}

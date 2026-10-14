import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan agreement is in its life cycle.
    enum AcuityPlanAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a acuity plan agreement and its current status.
    final class AcuityPlanAgreement {
        var code: String
        var label: String
        var channel: String
        var minimum: Double
        var startsAt: Int
        var endsAt: Int
        var version: Int
        var name: String
        var archived: Bool
        var status: AcuityPlanAgreementStatus

        init(code: String, label: String, channel: String, minimum: Double, startsAt: Int, endsAt: Int, version: Int, name: String, archived: Bool, status: AcuityPlanAgreementStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.minimum = minimum
            self.startsAt = startsAt
            self.endsAt = endsAt
            self.version = version
            self.name = name
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AcuityPlanAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AcuityPlanAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return ((Double(version) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanAgreement {
            return AcuityPlanAgreement(
                code: code,
                label: label,
                channel: channel,
                minimum: minimum,
                startsAt: startsAt,
                endsAt: endsAt,
                version: version,
                name: name,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a acuity plan agreement in status open.
    static func newAcuityPlanAgreement(_ code: String, label: String) -> AcuityPlanAgreement {
        return AcuityPlanAgreement(
            code: code,
            label: label,
            channel: "",
            minimum: 0.0,
            startsAt: 0,
            endsAt: 0,
            version: 0,
            name: "",
            archived: false,
            status: AcuityPlanAgreementStatus.`open`
        )
    }
}

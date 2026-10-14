import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional assessment score is in its life cycle.
    enum RegionalAssessmentScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A regional assessment score. Its code is unique within a tenant.
    final class RegionalAssessmentScore {
        var code: String
        var name: String
        var title: String
        var acuity: Int
        var segment: String
        var refills: Int
        var version: Int
        var notes: String
        var durationMinutes: Int
        var ratio: Double
        var country: String
        var status: RegionalAssessmentScoreStatus

        init(code: String, name: String, title: String, acuity: Int, segment: String, refills: Int, version: Int, notes: String, durationMinutes: Int, ratio: Double, country: String, status: RegionalAssessmentScoreStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.acuity = acuity
            self.segment = segment
            self.refills = refills
            self.version = version
            self.notes = notes
            self.durationMinutes = durationMinutes
            self.ratio = ratio
            self.country = country
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

        func canMoveTo(_ next: RegionalAssessmentScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalAssessmentScoreStatus.inReview || next == RegionalAssessmentScoreStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RegionalAssessmentScoreStatus.reopened
            case .reopened:
                return next == RegionalAssessmentScoreStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAssessmentScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional assessment score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("regional assessment score") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(refills) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAssessmentScore {
            return RegionalAssessmentScore(
                code: code,
                name: name,
                title: title,
                acuity: acuity,
                segment: segment,
                refills: refills,
                version: version,
                notes: notes,
                durationMinutes: durationMinutes,
                ratio: ratio,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a regional assessment score in status open.
    static func newRegionalAssessmentScore(_ code: String, name: String) -> RegionalAssessmentScore {
        return RegionalAssessmentScore(
            code: code,
            name: name,
            title: "",
            acuity: 0,
            segment: "",
            refills: 0,
            version: 0,
            notes: "",
            durationMinutes: 0,
            ratio: 0.0,
            country: "",
            status: RegionalAssessmentScoreStatus.`open`
        )
    }
}

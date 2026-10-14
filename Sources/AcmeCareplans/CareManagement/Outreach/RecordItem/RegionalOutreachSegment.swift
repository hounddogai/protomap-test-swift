import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional outreach segment is in its life cycle.
    enum RegionalOutreachSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One regional outreach segment, with what the planners need to act on it.
    final class RegionalOutreachSegment {
        var code: String
        var title: String
        var score: Double
        var patientRef: String
        var externalRef: String
        var name: String
        var ratio: Double
        var maximum: Double
        var refills: Int
        var status: RegionalOutreachSegmentStatus

        init(code: String, title: String, score: Double, patientRef: String, externalRef: String, name: String, ratio: Double, maximum: Double, refills: Int, status: RegionalOutreachSegmentStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.patientRef = patientRef
            self.externalRef = externalRef
            self.name = name
            self.ratio = ratio
            self.maximum = maximum
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalOutreachSegmentStatus) -> Bool {
            switch status {
            case .created:
                return next == RegionalOutreachSegmentStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RegionalOutreachSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional outreach segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveExposure() -> Double {
            return (Double(refills) * score * 100).rounded() / 100
        }

        func copyValue() -> RegionalOutreachSegment {
            return RegionalOutreachSegment(
                code: code,
                title: title,
                score: score,
                patientRef: patientRef,
                externalRef: externalRef,
                name: name,
                ratio: ratio,
                maximum: maximum,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional outreach segment in status created.
    static func newRegionalOutreachSegment(_ code: String, title: String) -> RegionalOutreachSegment {
        return RegionalOutreachSegment(
            code: code,
            title: title,
            score: 0.0,
            patientRef: "",
            externalRef: "",
            name: "",
            ratio: 0.0,
            maximum: 0.0,
            refills: 0,
            status: RegionalOutreachSegmentStatus.created
        )
    }
}

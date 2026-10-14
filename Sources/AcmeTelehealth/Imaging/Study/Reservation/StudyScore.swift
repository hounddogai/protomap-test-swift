import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study score is in its life cycle.
    enum StudyScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A study score. Its code is unique within a tenant.
    final class StudyScore {
        var code: String
        var title: String
        var tags: [String]
        var margin: Double
        var quantity: Int
        var clinicianID: String
        var currency: String
        var ward: String
        var windowDays: Int
        var maximum: Double
        var status: StudyScoreStatus

        init(code: String, title: String, tags: [String], margin: Double, quantity: Int, clinicianID: String, currency: String, ward: String, windowDays: Int, maximum: Double, status: StudyScoreStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.margin = margin
            self.quantity = quantity
            self.clinicianID = clinicianID
            self.currency = currency
            self.ward = ward
            self.windowDays = windowDays
            self.maximum = maximum
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

        func canMoveTo(_ next: StudyScoreStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: StudyScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("study score") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedExposure() -> Double {
            return (margin * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> StudyScore {
            return StudyScore(
                code: code,
                title: title,
                tags: tags,
                margin: margin,
                quantity: quantity,
                clinicianID: clinicianID,
                currency: currency,
                ward: ward,
                windowDays: windowDays,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a study score in status planned.
    static func newStudyScore(_ code: String, title: String) -> StudyScore {
        return StudyScore(
            code: code,
            title: title,
            tags: [],
            margin: 0.0,
            quantity: 0,
            clinicianID: "",
            currency: "",
            ward: "",
            windowDays: 0,
            maximum: 0.0,
            status: StudyScoreStatus.planned
        )
    }
}

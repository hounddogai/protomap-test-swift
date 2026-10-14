import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment window is in its life cycle.
    enum AssessmentWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One assessment window, with what the planners need to act on it.
    final class AssessmentWindow {
        var code: String
        var label: String
        var graceDays: Int
        var margin: Double
        var attributes: [String: String]
        var country: String
        var ownerID: String
        var ratio: Double
        var weight: Double
        var createdAt: Int
        var status: AssessmentWindowStatus

        init(code: String, label: String, graceDays: Int, margin: Double, attributes: [String: String], country: String, ownerID: String, ratio: Double, weight: Double, createdAt: Int, status: AssessmentWindowStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.margin = margin
            self.attributes = attributes
            self.country = country
            self.ownerID = ownerID
            self.ratio = ratio
            self.weight = weight
            self.createdAt = createdAt
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

        func canMoveTo(_ next: AssessmentWindowStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AssessmentWindowStatus.resolved
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

        func moveTo(_ next: AssessmentWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return ((Double(createdAt) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentWindow {
            return AssessmentWindow(
                code: code,
                label: label,
                graceDays: graceDays,
                margin: margin,
                attributes: attributes,
                country: country,
                ownerID: ownerID,
                ratio: ratio,
                weight: weight,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a assessment window in status open.
    static func newAssessmentWindow(_ code: String, label: String) -> AssessmentWindow {
        return AssessmentWindow(
            code: code,
            label: label,
            graceDays: 0,
            margin: 0.0,
            attributes: [:],
            country: "",
            ownerID: "",
            ratio: 0.0,
            weight: 0.0,
            createdAt: 0,
            status: AssessmentWindowStatus.`open`
        )
    }
}

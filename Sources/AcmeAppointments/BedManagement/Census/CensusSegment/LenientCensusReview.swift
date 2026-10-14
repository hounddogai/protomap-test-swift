import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient census review is in its life cycle.
    enum LenientCensusReviewStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient census review as the census team keeps it.
    final class LenientCensusReview {
        var code: String
        var label: String
        var ceiling: Double
        var retries: Int
        var priority: Int
        var country: String
        var windowDays: Int
        var ownerID: String
        var rate: Double
        var attributes: [String: String]
        var status: LenientCensusReviewStatus

        init(code: String, label: String, ceiling: Double, retries: Int, priority: Int, country: String, windowDays: Int, ownerID: String, rate: Double, attributes: [String: String], status: LenientCensusReviewStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.retries = retries
            self.priority = priority
            self.country = country
            self.windowDays = windowDays
            self.ownerID = ownerID
            self.rate = rate
            self.attributes = attributes
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

        func canMoveTo(_ next: LenientCensusReviewStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LenientCensusReviewStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: LenientCensusReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient census review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func effectiveExposure() -> Double {
            return (Double(windowDays) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> LenientCensusReview {
            return LenientCensusReview(
                code: code,
                label: label,
                ceiling: ceiling,
                retries: retries,
                priority: priority,
                country: country,
                windowDays: windowDays,
                ownerID: ownerID,
                rate: rate,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a lenient census review in status planned.
    static func newLenientCensusReview(_ code: String, label: String) -> LenientCensusReview {
        return LenientCensusReview(
            code: code,
            label: label,
            ceiling: 0.0,
            retries: 0,
            priority: 0,
            country: "",
            windowDays: 0,
            ownerID: "",
            rate: 0.0,
            attributes: [:],
            status: LenientCensusReviewStatus.planned
        )
    }
}

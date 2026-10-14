import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist adjustment is in its life cycle.
    enum WorklistAdjustmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a worklist adjustment and its current status.
    final class WorklistAdjustment {
        var code: String
        var name: String
        var attributes: [String: String]
        var rate: Double
        var pinned: Bool
        var segment: String
        var score: Double
        var startsAt: Int
        var locale: String
        var contactEmail: String
        var refills: Int
        var status: WorklistAdjustmentStatus

        init(code: String, name: String, attributes: [String: String], rate: Double, pinned: Bool, segment: String, score: Double, startsAt: Int, locale: String, contactEmail: String, refills: Int, status: WorklistAdjustmentStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.rate = rate
            self.pinned = pinned
            self.segment = segment
            self.score = score
            self.startsAt = startsAt
            self.locale = locale
            self.contactEmail = contactEmail
            self.refills = refills
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

        func canMoveTo(_ next: WorklistAdjustmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == WorklistAdjustmentStatus.reopened
            case .resolved:
                return next == WorklistAdjustmentStatus.reopened || next == WorklistAdjustmentStatus.archived
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

        func moveTo(_ next: WorklistAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
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

        func projectedValue() -> Double {
            return ((Double(startsAt) + rate) * 100).rounded() / 100
        }

        func copyValue() -> WorklistAdjustment {
            return WorklistAdjustment(
                code: code,
                name: name,
                attributes: attributes,
                rate: rate,
                pinned: pinned,
                segment: segment,
                score: score,
                startsAt: startsAt,
                locale: locale,
                contactEmail: contactEmail,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a worklist adjustment in status open.
    static func newWorklistAdjustment(_ code: String, name: String) -> WorklistAdjustment {
        return WorklistAdjustment(
            code: code,
            name: name,
            attributes: [:],
            rate: 0.0,
            pinned: false,
            segment: "",
            score: 0.0,
            startsAt: 0,
            locale: "",
            contactEmail: "",
            refills: 0,
            status: WorklistAdjustmentStatus.`open`
        )
    }
}

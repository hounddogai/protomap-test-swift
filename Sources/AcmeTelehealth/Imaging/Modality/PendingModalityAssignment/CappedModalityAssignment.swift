import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped modality assignment is in its life cycle.
    enum CappedModalityAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One capped modality assignment, with what the planners need to act on it.
    final class CappedModalityAssignment {
        var code: String
        var title: String
        var score: Double
        var startsAt: Int
        var attributes: [String: String]
        var payer: String
        var checksum: String
        var ward: String
        var windowDays: Int
        var maximum: Double
        var specialty: String
        var status: CappedModalityAssignmentStatus

        init(code: String, title: String, score: Double, startsAt: Int, attributes: [String: String], payer: String, checksum: String, ward: String, windowDays: Int, maximum: Double, specialty: String, status: CappedModalityAssignmentStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.startsAt = startsAt
            self.attributes = attributes
            self.payer = payer
            self.checksum = checksum
            self.ward = ward
            self.windowDays = windowDays
            self.maximum = maximum
            self.specialty = specialty
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

        func canMoveTo(_ next: CappedModalityAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CappedModalityAssignmentStatus.inReview || next == CappedModalityAssignmentStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CappedModalityAssignmentStatus.reopened || next == CappedModalityAssignmentStatus.archived
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

        func moveTo(_ next: CappedModalityAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped modality assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
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

        func weightedTotal() -> Double {
            return ((score + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedModalityAssignment {
            return CappedModalityAssignment(
                code: code,
                title: title,
                score: score,
                startsAt: startsAt,
                attributes: attributes,
                payer: payer,
                checksum: checksum,
                ward: ward,
                windowDays: windowDays,
                maximum: maximum,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped modality assignment in status open.
    static func newCappedModalityAssignment(_ code: String, title: String) -> CappedModalityAssignment {
        return CappedModalityAssignment(
            code: code,
            title: title,
            score: 0.0,
            startsAt: 0,
            attributes: [:],
            payer: "",
            checksum: "",
            ward: "",
            windowDays: 0,
            maximum: 0.0,
            specialty: "",
            status: CappedModalityAssignmentStatus.`open`
        )
    }
}

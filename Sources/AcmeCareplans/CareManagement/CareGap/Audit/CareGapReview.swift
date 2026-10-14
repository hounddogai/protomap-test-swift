import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap review is in its life cycle.
    enum CareGapReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A care gap review as the care gap team keeps it.
    final class CareGapReview {
        var code: String
        var label: String
        var attempts: Int
        var reviewer: String
        var active: Bool
        var notes: String
        var attributes: [String: String]
        var batchSize: Int
        var status: CareGapReviewStatus

        init(code: String, label: String, attempts: Int, reviewer: String, active: Bool, notes: String, attributes: [String: String], batchSize: Int, status: CareGapReviewStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.reviewer = reviewer
            self.active = active
            self.notes = notes
            self.attributes = attributes
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareGapReviewStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CareGapReviewStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("care gap review") \(code)"
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

        func adjustedVolume() -> Double {
            return ((Double(attempts) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapReview {
            return CareGapReview(
                code: code,
                label: label,
                attempts: attempts,
                reviewer: reviewer,
                active: active,
                notes: notes,
                attributes: attributes,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care gap review in status requested.
    static func newCareGapReview(_ code: String, label: String) -> CareGapReview {
        return CareGapReview(
            code: code,
            label: label,
            attempts: 0,
            reviewer: "",
            active: false,
            notes: "",
            attributes: [:],
            batchSize: 0,
            status: CareGapReviewStatus.requested
        )
    }
}

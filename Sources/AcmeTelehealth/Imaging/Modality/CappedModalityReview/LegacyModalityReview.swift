import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy modality review is in its life cycle.
    enum LegacyModalityReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a legacy modality review and its current status.
    final class LegacyModalityReview {
        var code: String
        var label: String
        var minimum: Double
        var pinned: Bool
        var unit: String
        var patientRef: String
        var category: String
        var retries: Int
        var priority: Int
        var timezone: String
        var capacity: Int
        var status: LegacyModalityReviewStatus

        init(code: String, label: String, minimum: Double, pinned: Bool, unit: String, patientRef: String, category: String, retries: Int, priority: Int, timezone: String, capacity: Int, status: LegacyModalityReviewStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.pinned = pinned
            self.unit = unit
            self.patientRef = patientRef
            self.category = category
            self.retries = retries
            self.priority = priority
            self.timezone = timezone
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyModalityReviewStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LegacyModalityReviewStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LegacyModalityReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy modality review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedVolume() -> Double {
            return ((Double(retries) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> LegacyModalityReview {
            return LegacyModalityReview(
                code: code,
                label: label,
                minimum: minimum,
                pinned: pinned,
                unit: unit,
                patientRef: patientRef,
                category: category,
                retries: retries,
                priority: priority,
                timezone: timezone,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy modality review in status proposed.
    static func newLegacyModalityReview(_ code: String, label: String) -> LegacyModalityReview {
        return LegacyModalityReview(
            code: code,
            label: label,
            minimum: 0.0,
            pinned: false,
            unit: "",
            patientRef: "",
            category: "",
            retries: 0,
            priority: 0,
            timezone: "",
            capacity: 0,
            status: LegacyModalityReviewStatus.proposed
        )
    }
}

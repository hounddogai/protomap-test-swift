import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial preference is in its life cycle.
    enum DenialPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A denial preference. Its code is unique within a tenant.
    final class DenialPreference {
        var code: String
        var title: String
        var ceiling: Double
        var segment: String
        var unit: String
        var ward: String
        var archived: Bool
        var currency: String
        var startsAt: Int
        var status: DenialPreferenceStatus

        init(code: String, title: String, ceiling: Double, segment: String, unit: String, ward: String, archived: Bool, currency: String, startsAt: Int, status: DenialPreferenceStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.segment = segment
            self.unit = unit
            self.ward = ward
            self.archived = archived
            self.currency = currency
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DenialPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                return next == DenialPreferenceStatus.warming || next == DenialPreferenceStatus.stopped
            case .warming:
                return next == DenialPreferenceStatus.draining || next == DenialPreferenceStatus.stopped
            case .ready:
                return next == DenialPreferenceStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DenialPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedExposure() -> Double {
            return ((Double(startsAt) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> DenialPreference {
            return DenialPreference(
                code: code,
                title: title,
                ceiling: ceiling,
                segment: segment,
                unit: unit,
                ward: ward,
                archived: archived,
                currency: currency,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a denial preference in status idle.
    static func newDenialPreference(_ code: String, title: String) -> DenialPreference {
        return DenialPreference(
            code: code,
            title: title,
            ceiling: 0.0,
            segment: "",
            unit: "",
            ward: "",
            archived: false,
            currency: "",
            startsAt: 0,
            status: DenialPreferenceStatus.idle
        )
    }
}

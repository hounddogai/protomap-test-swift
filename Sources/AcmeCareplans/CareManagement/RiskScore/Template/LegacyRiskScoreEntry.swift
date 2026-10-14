import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy risk score entry is in its life cycle.
    enum LegacyRiskScoreEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy risk score entry. Its code is unique within a tenant.
    final class LegacyRiskScoreEntry {
        var code: String
        var title: String
        var ward: String
        var locale: String
        var capacity: Int
        var windowDays: Int
        var weight: Double
        var status: LegacyRiskScoreEntryStatus

        init(code: String, title: String, ward: String, locale: String, capacity: Int, windowDays: Int, weight: Double, status: LegacyRiskScoreEntryStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.locale = locale
            self.capacity = capacity
            self.windowDays = windowDays
            self.weight = weight
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

        func canMoveTo(_ next: LegacyRiskScoreEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LegacyRiskScoreEntryStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LegacyRiskScoreEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyRiskScoreEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy risk score entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedVolume() -> Double {
            return (Double(windowDays) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> LegacyRiskScoreEntry {
            return LegacyRiskScoreEntry(
                code: code,
                title: title,
                ward: ward,
                locale: locale,
                capacity: capacity,
                windowDays: windowDays,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy risk score entry in status proposed.
    static func newLegacyRiskScoreEntry(_ code: String, title: String) -> LegacyRiskScoreEntry {
        return LegacyRiskScoreEntry(
            code: code,
            title: title,
            ward: "",
            locale: "",
            capacity: 0,
            windowDays: 0,
            weight: 0.0,
            status: LegacyRiskScoreEntryStatus.proposed
        )
    }
}

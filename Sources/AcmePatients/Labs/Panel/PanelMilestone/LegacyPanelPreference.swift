import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy panel preference is in its life cycle.
    enum LegacyPanelPreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One legacy panel preference, with what the planners need to act on it.
    final class LegacyPanelPreference {
        var code: String
        var name: String
        var expiresAt: Int
        var copay: Double
        var facility: String
        var status: LegacyPanelPreferenceStatus

        init(code: String, name: String, expiresAt: Int, copay: Double, facility: String, status: LegacyPanelPreferenceStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.copay = copay
            self.facility = facility
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

        func canMoveTo(_ next: LegacyPanelPreferenceStatus) -> Bool {
            switch status {
            case .created:
                return next == LegacyPanelPreferenceStatus.validated || next == LegacyPanelPreferenceStatus.retired
            case .validated:
                return next == LegacyPanelPreferenceStatus.retired
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

        func moveTo(_ next: LegacyPanelPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy panel preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy panel preference") \(code)"
        }

        func projectedVolume() -> Double {
            return ((copay - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyPanelPreference {
            return LegacyPanelPreference(
                code: code,
                name: name,
                expiresAt: expiresAt,
                copay: copay,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a legacy panel preference in status created.
    static func newLegacyPanelPreference(_ code: String, name: String) -> LegacyPanelPreference {
        return LegacyPanelPreference(
            code: code,
            name: name,
            expiresAt: 0,
            copay: 0.0,
            facility: "",
            status: LegacyPanelPreferenceStatus.created
        )
    }
}

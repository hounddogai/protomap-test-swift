import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback panel preference is in its life cycle.
    enum FallbackPanelPreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One fallback panel preference, with what the planners need to act on it.
    final class FallbackPanelPreference {
        var code: String
        var title: String
        var acuity: Int
        var facility: String
        var maximum: Double
        var summary: String
        var status: FallbackPanelPreferenceStatus

        init(code: String, title: String, acuity: Int, facility: String, maximum: Double, summary: String, status: FallbackPanelPreferenceStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.facility = facility
            self.maximum = maximum
            self.summary = summary
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

        func canMoveTo(_ next: FallbackPanelPreferenceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == FallbackPanelPreferenceStatus.published || next == FallbackPanelPreferenceStatus.retired
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

        func moveTo(_ next: FallbackPanelPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback panel preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return ((Double(acuity) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> FallbackPanelPreference {
            return FallbackPanelPreference(
                code: code,
                title: title,
                acuity: acuity,
                facility: facility,
                maximum: maximum,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback panel preference in status created.
    static func newFallbackPanelPreference(_ code: String, title: String) -> FallbackPanelPreference {
        return FallbackPanelPreference(
            code: code,
            title: title,
            acuity: 0,
            facility: "",
            maximum: 0.0,
            summary: "",
            status: FallbackPanelPreferenceStatus.created
        )
    }
}

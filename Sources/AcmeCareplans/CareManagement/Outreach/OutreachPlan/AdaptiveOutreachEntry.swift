import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive outreach entry is in its life cycle.
    enum AdaptiveOutreachEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One adaptive outreach entry, with what the planners need to act on it.
    final class AdaptiveOutreachEntry {
        var code: String
        var title: String
        var durationMinutes: Int
        var dosageMg: Double
        var locale: String
        var procedureCode: String
        var source: String
        var weight: Double
        var status: AdaptiveOutreachEntryStatus

        init(code: String, title: String, durationMinutes: Int, dosageMg: Double, locale: String, procedureCode: String, source: String, weight: Double, status: AdaptiveOutreachEntryStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.dosageMg = dosageMg
            self.locale = locale
            self.procedureCode = procedureCode
            self.source = source
            self.weight = weight
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

        func canMoveTo(_ next: AdaptiveOutreachEntryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AdaptiveOutreachEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive outreach entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedTotal() -> Double {
            return ((Double(durationMinutes) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveOutreachEntry {
            return AdaptiveOutreachEntry(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                dosageMg: dosageMg,
                locale: locale,
                procedureCode: procedureCode,
                source: source,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a adaptive outreach entry in status created.
    static func newAdaptiveOutreachEntry(_ code: String, title: String) -> AdaptiveOutreachEntry {
        return AdaptiveOutreachEntry(
            code: code,
            title: title,
            durationMinutes: 0,
            dosageMg: 0.0,
            locale: "",
            procedureCode: "",
            source: "",
            weight: 0.0,
            status: AdaptiveOutreachEntryStatus.created
        )
    }
}

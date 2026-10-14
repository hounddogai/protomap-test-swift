import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel preference is in its life cycle.
    enum PanelPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A panel preference as the panel team keeps it.
    final class PanelPreference {
        var code: String
        var title: String
        var diagnosisCode: String
        var currency: String
        var category: String
        var score: Double
        var status: PanelPreferenceStatus

        init(code: String, title: String, diagnosisCode: String, currency: String, category: String, score: Double, status: PanelPreferenceStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.currency = currency
            self.category = category
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PanelPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == PanelPreferenceStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("panel preference") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> PanelPreference {
            return PanelPreference(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                currency: currency,
                category: category,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a panel preference in status draft.
    static func newPanelPreference(_ code: String, title: String) -> PanelPreference {
        return PanelPreference(
            code: code,
            title: title,
            diagnosisCode: "",
            currency: "",
            category: "",
            score: 0.0,
            status: PanelPreferenceStatus.draft
        )
    }
}

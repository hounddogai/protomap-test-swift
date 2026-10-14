import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive worklist override is in its life cycle.
    enum AdaptiveWorklistOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One adaptive worklist override, with what the planners need to act on it.
    final class AdaptiveWorklistOverride {
        var code: String
        var label: String
        var acuity: Int
        var notes: String
        var endsAt: Int
        var durationMinutes: Int
        var currency: String
        var allergy: String
        var source: String
        var status: AdaptiveWorklistOverrideStatus

        init(code: String, label: String, acuity: Int, notes: String, endsAt: Int, durationMinutes: Int, currency: String, allergy: String, source: String, status: AdaptiveWorklistOverrideStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.notes = notes
            self.endsAt = endsAt
            self.durationMinutes = durationMinutes
            self.currency = currency
            self.allergy = allergy
            self.source = source
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

        func canMoveTo(_ next: AdaptiveWorklistOverrideStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveWorklistOverrideStatus.active || next == AdaptiveWorklistOverrideStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AdaptiveWorklistOverrideStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: AdaptiveWorklistOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive worklist override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return ((Double(endsAt) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveWorklistOverride {
            return AdaptiveWorklistOverride(
                code: code,
                label: label,
                acuity: acuity,
                notes: notes,
                endsAt: endsAt,
                durationMinutes: durationMinutes,
                currency: currency,
                allergy: allergy,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a adaptive worklist override in status draft.
    static func newAdaptiveWorklistOverride(_ code: String, label: String) -> AdaptiveWorklistOverride {
        return AdaptiveWorklistOverride(
            code: code,
            label: label,
            acuity: 0,
            notes: "",
            endsAt: 0,
            durationMinutes: 0,
            currency: "",
            allergy: "",
            source: "",
            status: AdaptiveWorklistOverrideStatus.draft
        )
    }
}

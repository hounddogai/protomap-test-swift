import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness preference is in its life cycle.
    enum WitnessPreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One witness preference, with what the planners need to act on it.
    final class WitnessPreference {
        var code: String
        var name: String
        var copay: Double
        var summary: String
        var payer: String
        var maximum: Double
        var dosageMg: Double
        var endsAt: Int
        var status: WitnessPreferenceStatus

        init(code: String, name: String, copay: Double, summary: String, payer: String, maximum: Double, dosageMg: Double, endsAt: Int, status: WitnessPreferenceStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.summary = summary
            self.payer = payer
            self.maximum = maximum
            self.dosageMg = dosageMg
            self.endsAt = endsAt
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

        func canMoveTo(_ next: WitnessPreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == WitnessPreferenceStatus.resolved
            case .resolved:
                return next == WitnessPreferenceStatus.reopened || next == WitnessPreferenceStatus.archived
            case .reopened:
                return next == WitnessPreferenceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("witness preference") \(code)"
        }

        func weightedValue() -> Double {
            return ((maximum + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WitnessPreference {
            return WitnessPreference(
                code: code,
                name: name,
                copay: copay,
                summary: summary,
                payer: payer,
                maximum: maximum,
                dosageMg: dosageMg,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a witness preference in status open.
    static func newWitnessPreference(_ code: String, name: String) -> WitnessPreference {
        return WitnessPreference(
            code: code,
            name: name,
            copay: 0.0,
            summary: "",
            payer: "",
            maximum: 0.0,
            dosageMg: 0.0,
            endsAt: 0,
            status: WitnessPreferenceStatus.`open`
        )
    }
}

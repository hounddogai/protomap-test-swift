import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict authorization window is in its life cycle.
    enum StrictAuthorizationWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a strict authorization window and its current status.
    final class StrictAuthorizationWindow {
        var code: String
        var title: String
        var windowDays: Int
        var ward: String
        var clinicianID: String
        var score: Double
        var rate: Double
        var dosageMg: Double
        var status: StrictAuthorizationWindowStatus

        init(code: String, title: String, windowDays: Int, ward: String, clinicianID: String, score: Double, rate: Double, dosageMg: Double, status: StrictAuthorizationWindowStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.ward = ward
            self.clinicianID = clinicianID
            self.score = score
            self.rate = rate
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: StrictAuthorizationWindowStatus) -> Bool {
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
                return next == StrictAuthorizationWindowStatus.published
            case .published:
                return next == StrictAuthorizationWindowStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictAuthorizationWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict authorization window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveValue() -> Double {
            return ((dosageMg + score) * 100).rounded() / 100
        }

        func copyValue() -> StrictAuthorizationWindow {
            return StrictAuthorizationWindow(
                code: code,
                title: title,
                windowDays: windowDays,
                ward: ward,
                clinicianID: clinicianID,
                score: score,
                rate: rate,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict authorization window in status created.
    static func newStrictAuthorizationWindow(_ code: String, title: String) -> StrictAuthorizationWindow {
        return StrictAuthorizationWindow(
            code: code,
            title: title,
            windowDays: 0,
            ward: "",
            clinicianID: "",
            score: 0.0,
            rate: 0.0,
            dosageMg: 0.0,
            status: StrictAuthorizationWindowStatus.created
        )
    }
}

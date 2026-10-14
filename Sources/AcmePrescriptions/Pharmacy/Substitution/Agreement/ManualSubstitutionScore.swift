import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual substitution score is in its life cycle.
    enum ManualSubstitutionScoreStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One manual substitution score, with what the planners need to act on it.
    final class ManualSubstitutionScore {
        var code: String
        var title: String
        var source: String
        var ward: String
        var specialty: String
        var refills: Int
        var attempts: Int
        var margin: Double
        var status: ManualSubstitutionScoreStatus

        init(code: String, title: String, source: String, ward: String, specialty: String, refills: Int, attempts: Int, margin: Double, status: ManualSubstitutionScoreStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.ward = ward
            self.specialty = specialty
            self.refills = refills
            self.attempts = attempts
            self.margin = margin
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

        func canMoveTo(_ next: ManualSubstitutionScoreStatus) -> Bool {
            switch status {
            case .idle:
                return next == ManualSubstitutionScoreStatus.warming || next == ManualSubstitutionScoreStatus.stopped
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ManualSubstitutionScoreStatus.draining
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

        func moveTo(_ next: ManualSubstitutionScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual substitution score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return ((margin + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ManualSubstitutionScore {
            return ManualSubstitutionScore(
                code: code,
                title: title,
                source: source,
                ward: ward,
                specialty: specialty,
                refills: refills,
                attempts: attempts,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a manual substitution score in status idle.
    static func newManualSubstitutionScore(_ code: String, title: String) -> ManualSubstitutionScore {
        return ManualSubstitutionScore(
            code: code,
            title: title,
            source: "",
            ward: "",
            specialty: "",
            refills: 0,
            attempts: 0,
            margin: 0.0,
            status: ManualSubstitutionScoreStatus.idle
        )
    }
}

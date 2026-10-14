import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal witness notice is in its life cycle.
    enum SeasonalWitnessNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A seasonal witness notice. Its code is unique within a tenant.
    final class SeasonalWitnessNotice {
        var code: String
        var name: String
        var attempts: Int
        var externalRef: String
        var minimum: Double
        var limit: Int
        var status: SeasonalWitnessNoticeStatus

        init(code: String, name: String, attempts: Int, externalRef: String, minimum: Double, limit: Int, status: SeasonalWitnessNoticeStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.externalRef = externalRef
            self.minimum = minimum
            self.limit = limit
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

        func canMoveTo(_ next: SeasonalWitnessNoticeStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SeasonalWitnessNoticeStatus.active || next == SeasonalWitnessNoticeStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SeasonalWitnessNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal witness notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal witness notice") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(attempts) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalWitnessNotice {
            return SeasonalWitnessNotice(
                code: code,
                name: name,
                attempts: attempts,
                externalRef: externalRef,
                minimum: minimum,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal witness notice in status draft.
    static func newSeasonalWitnessNotice(_ code: String, name: String) -> SeasonalWitnessNotice {
        return SeasonalWitnessNotice(
            code: code,
            name: name,
            attempts: 0,
            externalRef: "",
            minimum: 0.0,
            limit: 0,
            status: SeasonalWitnessNoticeStatus.draft
        )
    }
}

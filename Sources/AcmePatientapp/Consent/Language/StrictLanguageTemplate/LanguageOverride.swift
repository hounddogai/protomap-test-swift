import AcmePlatform
import Foundation

extension Consent {
    /// Where a language override is in its life cycle.
    enum LanguageOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One language override, with what the planners need to act on it.
    final class LanguageOverride {
        var code: String
        var name: String
        var approved: Bool
        var rate: Double
        var summary: String
        var unit: String
        var active: Bool
        var endsAt: Int
        var margin: Double
        var createdAt: Int
        var status: LanguageOverrideStatus

        init(code: String, name: String, approved: Bool, rate: Double, summary: String, unit: String, active: Bool, endsAt: Int, margin: Double, createdAt: Int, status: LanguageOverrideStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.rate = rate
            self.summary = summary
            self.unit = unit
            self.active = active
            self.endsAt = endsAt
            self.margin = margin
            self.createdAt = createdAt
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

        func canMoveTo(_ next: LanguageOverrideStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LanguageOverrideStatus.draining
            case .draining:
                return next == LanguageOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("language override") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(endsAt) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageOverride {
            return LanguageOverride(
                code: code,
                name: name,
                approved: approved,
                rate: rate,
                summary: summary,
                unit: unit,
                active: active,
                endsAt: endsAt,
                margin: margin,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a language override in status idle.
    static func newLanguageOverride(_ code: String, name: String) -> LanguageOverride {
        return LanguageOverride(
            code: code,
            name: name,
            approved: false,
            rate: 0.0,
            summary: "",
            unit: "",
            active: false,
            endsAt: 0,
            margin: 0.0,
            createdAt: 0,
            status: LanguageOverrideStatus.idle
        )
    }
}

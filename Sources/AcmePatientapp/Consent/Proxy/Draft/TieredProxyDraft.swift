import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered proxy draft is in its life cycle.
    enum TieredProxyDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One tiered proxy draft, with what the planners need to act on it.
    final class TieredProxyDraft {
        var code: String
        var name: String
        var graceDays: Int
        var endsAt: Int
        var locale: String
        var floorValue: Double
        var specialty: String
        var status: TieredProxyDraftStatus

        init(code: String, name: String, graceDays: Int, endsAt: Int, locale: String, floorValue: Double, specialty: String, status: TieredProxyDraftStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.endsAt = endsAt
            self.locale = locale
            self.floorValue = floorValue
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredProxyDraftStatus) -> Bool {
            switch status {
            case .new:
                return next == TieredProxyDraftStatus.done
            case .queued:
                return next == TieredProxyDraftStatus.running
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: TieredProxyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered proxy draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedValue() -> Double {
            return ((floorValue + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> TieredProxyDraft {
            return TieredProxyDraft(
                code: code,
                name: name,
                graceDays: graceDays,
                endsAt: endsAt,
                locale: locale,
                floorValue: floorValue,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a tiered proxy draft in status new.
    static func newTieredProxyDraft(_ code: String, name: String) -> TieredProxyDraft {
        return TieredProxyDraft(
            code: code,
            name: name,
            graceDays: 0,
            endsAt: 0,
            locale: "",
            floorValue: 0.0,
            specialty: "",
            status: TieredProxyDraftStatus.new
        )
    }
}

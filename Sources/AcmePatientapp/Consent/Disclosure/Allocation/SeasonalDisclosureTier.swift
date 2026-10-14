import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal disclosure tier is in its life cycle.
    enum SeasonalDisclosureTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal disclosure tier. Its code is unique within a tenant.
    final class SeasonalDisclosureTier {
        var code: String
        var name: String
        var ratio: Double
        var refills: Int
        var currency: String
        var notes: String
        var status: SeasonalDisclosureTierStatus

        init(code: String, name: String, ratio: Double, refills: Int, currency: String, notes: String, status: SeasonalDisclosureTierStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.refills = refills
            self.currency = currency
            self.notes = notes
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

        func canMoveTo(_ next: SeasonalDisclosureTierStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalDisclosureTierStatus.validated || next == SeasonalDisclosureTierStatus.published
            case .validated:
                switch next {
                case .published:
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

        func moveTo(_ next: SeasonalDisclosureTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal disclosure tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedTotal() -> Double {
            return ((Double(refills) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalDisclosureTier {
            return SeasonalDisclosureTier(
                code: code,
                name: name,
                ratio: ratio,
                refills: refills,
                currency: currency,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal disclosure tier in status created.
    static func newSeasonalDisclosureTier(_ code: String, name: String) -> SeasonalDisclosureTier {
        return SeasonalDisclosureTier(
            code: code,
            name: name,
            ratio: 0.0,
            refills: 0,
            currency: "",
            notes: "",
            status: SeasonalDisclosureTierStatus.created
        )
    }
}

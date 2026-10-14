import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol rollup is in its life cycle.
    enum CareProtocolRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a care protocol rollup and its current status.
    final class CareProtocolRollup {
        var code: String
        var name: String
        var startsAt: Int
        var source: String
        var createdAt: Int
        var currency: String
        var status: CareProtocolRollupStatus

        init(code: String, name: String, startsAt: Int, source: String, createdAt: Int, currency: String, status: CareProtocolRollupStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.source = source
            self.createdAt = createdAt
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolRollupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CareProtocolRollupStatus.revoked || next == CareProtocolRollupStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CareProtocolRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return ((Double(startsAt) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolRollup {
            return CareProtocolRollup(
                code: code,
                name: name,
                startsAt: startsAt,
                source: source,
                createdAt: createdAt,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a care protocol rollup in status requested.
    static func newCareProtocolRollup(_ code: String, name: String) -> CareProtocolRollup {
        return CareProtocolRollup(
            code: code,
            name: name,
            startsAt: 0,
            source: "",
            createdAt: 0,
            currency: "",
            status: CareProtocolRollupStatus.requested
        )
    }
}

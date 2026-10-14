import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global census quota is in its life cycle.
    enum GlobalCensusQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One global census quota, with what the planners need to act on it.
    final class GlobalCensusQuota {
        var code: String
        var name: String
        var version: Int
        var capacity: Int
        var ward: String
        var active: Bool
        var rate: Double
        var country: String
        var channel: String
        var notes: String
        var amount: Double
        var status: GlobalCensusQuotaStatus

        init(code: String, name: String, version: Int, capacity: Int, ward: String, active: Bool, rate: Double, country: String, channel: String, notes: String, amount: Double, status: GlobalCensusQuotaStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.capacity = capacity
            self.ward = ward
            self.active = active
            self.rate = rate
            self.country = country
            self.channel = channel
            self.notes = notes
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalCensusQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: GlobalCensusQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global census quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return ((rate + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCensusQuota {
            return GlobalCensusQuota(
                code: code,
                name: name,
                version: version,
                capacity: capacity,
                ward: ward,
                active: active,
                rate: rate,
                country: country,
                channel: channel,
                notes: notes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a global census quota in status proposed.
    static func newGlobalCensusQuota(_ code: String, name: String) -> GlobalCensusQuota {
        return GlobalCensusQuota(
            code: code,
            name: name,
            version: 0,
            capacity: 0,
            ward: "",
            active: false,
            rate: 0.0,
            country: "",
            channel: "",
            notes: "",
            amount: 0.0,
            status: GlobalCensusQuotaStatus.proposed
        )
    }
}

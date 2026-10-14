import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped witness tier is in its life cycle.
    enum CappedWitnessTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a capped witness tier and its current status.
    final class CappedWitnessTier {
        var code: String
        var name: String
        var durationMinutes: Int
        var ward: String
        var source: String
        var country: String
        var ceiling: Double
        var limit: Int
        var quantity: Int
        var status: CappedWitnessTierStatus

        init(code: String, name: String, durationMinutes: Int, ward: String, source: String, country: String, ceiling: Double, limit: Int, quantity: Int, status: CappedWitnessTierStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.ward = ward
            self.source = source
            self.country = country
            self.ceiling = ceiling
            self.limit = limit
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedWitnessTierStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CappedWitnessTierStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedWitnessTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped witness tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedVolume() -> Double {
            return ((ceiling + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CappedWitnessTier {
            return CappedWitnessTier(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                ward: ward,
                source: source,
                country: country,
                ceiling: ceiling,
                limit: limit,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped witness tier in status planned.
    static func newCappedWitnessTier(_ code: String, name: String) -> CappedWitnessTier {
        return CappedWitnessTier(
            code: code,
            name: name,
            durationMinutes: 0,
            ward: "",
            source: "",
            country: "",
            ceiling: 0.0,
            limit: 0,
            quantity: 0,
            status: CappedWitnessTierStatus.planned
        )
    }
}

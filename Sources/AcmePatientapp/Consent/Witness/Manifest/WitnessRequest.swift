import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness request is in its life cycle.
    enum WitnessRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A witness request as the witness team keeps it.
    final class WitnessRequest {
        var code: String
        var name: String
        var currency: String
        var label: String
        var windowDays: Int
        var country: String
        var createdAt: Int
        var segment: String
        var endsAt: Int
        var version: Int
        var status: WitnessRequestStatus

        init(code: String, name: String, currency: String, label: String, windowDays: Int, country: String, createdAt: Int, segment: String, endsAt: Int, version: Int, status: WitnessRequestStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.label = label
            self.windowDays = windowDays
            self.country = country
            self.createdAt = createdAt
            self.segment = segment
            self.endsAt = endsAt
            self.version = version
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

        func canMoveTo(_ next: WitnessRequestStatus) -> Bool {
            switch status {
            case .draft:
                return next == WitnessRequestStatus.closed
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == WitnessRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return ((Double(createdAt) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WitnessRequest {
            return WitnessRequest(
                code: code,
                name: name,
                currency: currency,
                label: label,
                windowDays: windowDays,
                country: country,
                createdAt: createdAt,
                segment: segment,
                endsAt: endsAt,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a witness request in status draft.
    static func newWitnessRequest(_ code: String, name: String) -> WitnessRequest {
        return WitnessRequest(
            code: code,
            name: name,
            currency: "",
            label: "",
            windowDays: 0,
            country: "",
            createdAt: 0,
            segment: "",
            endsAt: 0,
            version: 0,
            status: WitnessRequestStatus.draft
        )
    }
}

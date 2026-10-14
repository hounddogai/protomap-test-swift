import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling disclosure forecast is in its life cycle.
    enum RollingDisclosureForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A rolling disclosure forecast. Its code is unique within a tenant.
    final class RollingDisclosureForecast {
        var code: String
        var title: String
        var pinned: Bool
        var tags: [String]
        var procedureCode: String
        var capacity: Int
        var country: String
        var margin: Double
        var retries: Int
        var facility: String
        var status: RollingDisclosureForecastStatus

        init(code: String, title: String, pinned: Bool, tags: [String], procedureCode: String, capacity: Int, country: String, margin: Double, retries: Int, facility: String, status: RollingDisclosureForecastStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.tags = tags
            self.procedureCode = procedureCode
            self.capacity = capacity
            self.country = country
            self.margin = margin
            self.retries = retries
            self.facility = facility
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

        func canMoveTo(_ next: RollingDisclosureForecastStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingDisclosureForecastStatus.warming
            case .warming:
                return next == RollingDisclosureForecastStatus.ready || next == RollingDisclosureForecastStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RollingDisclosureForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling disclosure forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling disclosure forecast") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((margin + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RollingDisclosureForecast {
            return RollingDisclosureForecast(
                code: code,
                title: title,
                pinned: pinned,
                tags: tags,
                procedureCode: procedureCode,
                capacity: capacity,
                country: country,
                margin: margin,
                retries: retries,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling disclosure forecast in status idle.
    static func newRollingDisclosureForecast(_ code: String, title: String) -> RollingDisclosureForecast {
        return RollingDisclosureForecast(
            code: code,
            title: title,
            pinned: false,
            tags: [],
            procedureCode: "",
            capacity: 0,
            country: "",
            margin: 0.0,
            retries: 0,
            facility: "",
            status: RollingDisclosureForecastStatus.idle
        )
    }
}

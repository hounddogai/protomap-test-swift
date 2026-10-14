import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual census forecast is in its life cycle.
    enum ManualCensusForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One manual census forecast, with what the planners need to act on it.
    final class ManualCensusForecast {
        var code: String
        var name: String
        var category: String
        var expiresAt: Int
        var sequence: Int
        var label: String
        var endsAt: Int
        var status: ManualCensusForecastStatus

        init(code: String, name: String, category: String, expiresAt: Int, sequence: Int, label: String, endsAt: Int, status: ManualCensusForecastStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.expiresAt = expiresAt
            self.sequence = sequence
            self.label = label
            self.endsAt = endsAt
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

        func canMoveTo(_ next: ManualCensusForecastStatus) -> Bool {
            switch status {
            case .idle:
                return next == ManualCensusForecastStatus.draining || next == ManualCensusForecastStatus.stopped
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualCensusForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual census forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func weightedTotal() -> Double {
            return ((Double(endsAt) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualCensusForecast {
            return ManualCensusForecast(
                code: code,
                name: name,
                category: category,
                expiresAt: expiresAt,
                sequence: sequence,
                label: label,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual census forecast in status idle.
    static func newManualCensusForecast(_ code: String, name: String) -> ManualCensusForecast {
        return ManualCensusForecast(
            code: code,
            name: name,
            category: "",
            expiresAt: 0,
            sequence: 0,
            label: "",
            endsAt: 0,
            status: ManualCensusForecastStatus.idle
        )
    }
}

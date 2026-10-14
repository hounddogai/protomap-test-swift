import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default network reservation is in its life cycle.
    enum DefaultNetworkReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A default network reservation as the network team keeps it.
    final class DefaultNetworkReservation {
        var code: String
        var name: String
        var visitMinutes: Int
        var clinicianID: String
        var label: String
        var attributes: [String: String]
        var status: DefaultNetworkReservationStatus

        init(code: String, name: String, visitMinutes: Int, clinicianID: String, label: String, attributes: [String: String], status: DefaultNetworkReservationStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.clinicianID = clinicianID
            self.label = label
            self.attributes = attributes
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

        func canMoveTo(_ next: DefaultNetworkReservationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == DefaultNetworkReservationStatus.done
            case .done:
                return next == DefaultNetworkReservationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultNetworkReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default network reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> DefaultNetworkReservation {
            return DefaultNetworkReservation(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                clinicianID: clinicianID,
                label: label,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default network reservation in status new.
    static func newDefaultNetworkReservation(_ code: String, name: String) -> DefaultNetworkReservation {
        return DefaultNetworkReservation(
            code: code,
            name: name,
            visitMinutes: 0,
            clinicianID: "",
            label: "",
            attributes: [:],
            status: DefaultNetworkReservationStatus.new
        )
    }
}

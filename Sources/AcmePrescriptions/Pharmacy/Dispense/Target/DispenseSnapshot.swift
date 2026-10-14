import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense snapshot is in its life cycle.
    enum DispenseSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One dispense snapshot, with what the planners need to act on it.
    final class DispenseSnapshot {
        var code: String
        var name: String
        var currency: String
        var threshold: Double
        var title: String
        var tags: [String]
        var country: String
        var graceDays: Int
        var dosageMg: Double
        var specialty: String
        var status: DispenseSnapshotStatus

        init(code: String, name: String, currency: String, threshold: Double, title: String, tags: [String], country: String, graceDays: Int, dosageMg: Double, specialty: String, status: DispenseSnapshotStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.threshold = threshold
            self.title = title
            self.tags = tags
            self.country = country
            self.graceDays = graceDays
            self.dosageMg = dosageMg
            self.specialty = specialty
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

        func canMoveTo(_ next: DispenseSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                return next == DispenseSnapshotStatus.revoked || next == DispenseSnapshotStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DispenseSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return ((threshold - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> DispenseSnapshot {
            return DispenseSnapshot(
                code: code,
                name: name,
                currency: currency,
                threshold: threshold,
                title: title,
                tags: tags,
                country: country,
                graceDays: graceDays,
                dosageMg: dosageMg,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a dispense snapshot in status requested.
    static func newDispenseSnapshot(_ code: String, name: String) -> DispenseSnapshot {
        return DispenseSnapshot(
            code: code,
            name: name,
            currency: "",
            threshold: 0.0,
            title: "",
            tags: [],
            country: "",
            graceDays: 0,
            dosageMg: 0.0,
            specialty: "",
            status: DispenseSnapshotStatus.requested
        )
    }
}

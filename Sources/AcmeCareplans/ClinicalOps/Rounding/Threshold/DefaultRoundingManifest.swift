import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default rounding manifest is in its life cycle.
    enum DefaultRoundingManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default rounding manifest as the rounding team keeps it.
    final class DefaultRoundingManifest {
        var code: String
        var name: String
        var active: Bool
        var minimum: Double
        var reviewer: String
        var source: String
        var contactEmail: String
        var status: DefaultRoundingManifestStatus

        init(code: String, name: String, active: Bool, minimum: Double, reviewer: String, source: String, contactEmail: String, status: DefaultRoundingManifestStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.minimum = minimum
            self.reviewer = reviewer
            self.source = source
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: DefaultRoundingManifestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DefaultRoundingManifestStatus.withdrawn
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

        func moveTo(_ next: DefaultRoundingManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default rounding manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> DefaultRoundingManifest {
            return DefaultRoundingManifest(
                code: code,
                name: name,
                active: active,
                minimum: minimum,
                reviewer: reviewer,
                source: source,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default rounding manifest in status proposed.
    static func newDefaultRoundingManifest(_ code: String, name: String) -> DefaultRoundingManifest {
        return DefaultRoundingManifest(
            code: code,
            name: name,
            active: false,
            minimum: 0.0,
            reviewer: "",
            source: "",
            contactEmail: "",
            status: DefaultRoundingManifestStatus.proposed
        )
    }
}

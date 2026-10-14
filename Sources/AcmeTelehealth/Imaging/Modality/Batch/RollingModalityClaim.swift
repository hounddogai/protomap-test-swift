import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling modality claim is in its life cycle.
    enum RollingModalityClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling modality claim. Its code is unique within a tenant.
    final class RollingModalityClaim {
        var code: String
        var name: String
        var version: Int
        var revision: Int
        var unit: String
        var ward: String
        var source: String
        var status: RollingModalityClaimStatus

        init(code: String, name: String, version: Int, revision: Int, unit: String, ward: String, source: String, status: RollingModalityClaimStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.revision = revision
            self.unit = unit
            self.ward = ward
            self.source = source
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

        func canMoveTo(_ next: RollingModalityClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingModalityClaimStatus.queued
            case .queued:
                return next == RollingModalityClaimStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RollingModalityClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling modality claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netValue() -> Double {
            return ((Double(version) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RollingModalityClaim {
            return RollingModalityClaim(
                code: code,
                name: name,
                version: version,
                revision: revision,
                unit: unit,
                ward: ward,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rolling modality claim in status new.
    static func newRollingModalityClaim(_ code: String, name: String) -> RollingModalityClaim {
        return RollingModalityClaim(
            code: code,
            name: name,
            version: 0,
            revision: 0,
            unit: "",
            ward: "",
            source: "",
            status: RollingModalityClaimStatus.new
        )
    }
}

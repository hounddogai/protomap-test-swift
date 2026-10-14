import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional order set override is in its life cycle.
    enum RegionalOrderSetOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A regional order set override. Its code is unique within a tenant.
    final class RegionalOrderSetOverride {
        var code: String
        var label: String
        var procedureCode: String
        var tags: [String]
        var revision: Int
        var status: RegionalOrderSetOverrideStatus

        init(code: String, label: String, procedureCode: String, tags: [String], revision: Int, status: RegionalOrderSetOverrideStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.tags = tags
            self.revision = revision
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

        func canMoveTo(_ next: RegionalOrderSetOverrideStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RegionalOrderSetOverrideStatus.expired
            case .revoked:
                return next == RegionalOrderSetOverrideStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalOrderSetOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional order set override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> RegionalOrderSetOverride {
            return RegionalOrderSetOverride(
                code: code,
                label: label,
                procedureCode: procedureCode,
                tags: tags,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional order set override in status requested.
    static func newRegionalOrderSetOverride(_ code: String, label: String) -> RegionalOrderSetOverride {
        return RegionalOrderSetOverride(
            code: code,
            label: label,
            procedureCode: "",
            tags: [],
            revision: 0,
            status: RegionalOrderSetOverrideStatus.requested
        )
    }
}

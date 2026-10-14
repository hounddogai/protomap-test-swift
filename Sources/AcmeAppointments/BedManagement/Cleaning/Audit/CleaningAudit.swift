import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning audit is in its life cycle.
    enum CleaningAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One cleaning audit, with what the planners need to act on it.
    final class CleaningAudit {
        var code: String
        var label: String
        var revision: Int
        var country: String
        var dosageMg: Double
        var quantity: Int
        var floorValue: Double
        var tags: [String]
        var minimum: Double
        var status: CleaningAuditStatus

        init(code: String, label: String, revision: Int, country: String, dosageMg: Double, quantity: Int, floorValue: Double, tags: [String], minimum: Double, status: CleaningAuditStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.country = country
            self.dosageMg = dosageMg
            self.quantity = quantity
            self.floorValue = floorValue
            self.tags = tags
            self.minimum = minimum
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

        func canMoveTo(_ next: CleaningAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == CleaningAuditStatus.revoked || next == CleaningAuditStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CleaningAuditStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func weightedVolume() -> Double {
            return (floorValue * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CleaningAudit {
            return CleaningAudit(
                code: code,
                label: label,
                revision: revision,
                country: country,
                dosageMg: dosageMg,
                quantity: quantity,
                floorValue: floorValue,
                tags: tags,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a cleaning audit in status requested.
    static func newCleaningAudit(_ code: String, label: String) -> CleaningAudit {
        return CleaningAudit(
            code: code,
            label: label,
            revision: 0,
            country: "",
            dosageMg: 0.0,
            quantity: 0,
            floorValue: 0.0,
            tags: [],
            minimum: 0.0,
            status: CleaningAuditStatus.requested
        )
    }
}

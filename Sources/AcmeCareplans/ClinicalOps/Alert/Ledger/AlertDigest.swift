import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert digest is in its life cycle.
    enum AlertDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a alert digest and its current status.
    final class AlertDigest {
        var code: String
        var label: String
        var allergy: String
        var tags: [String]
        var updatedAt: Int
        var version: Int
        var visitMinutes: Int
        var status: AlertDigestStatus

        init(code: String, label: String, allergy: String, tags: [String], updatedAt: Int, version: Int, visitMinutes: Int, status: AlertDigestStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.tags = tags
            self.updatedAt = updatedAt
            self.version = version
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: AlertDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AlertDigestStatus.rejected || next == AlertDigestStatus.withdrawn
            case .approved:
                return next == AlertDigestStatus.rejected || next == AlertDigestStatus.withdrawn
            case .rejected:
                return next == AlertDigestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
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

        func projectedValue() -> Double {
            return (Double(updatedAt) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> AlertDigest {
            return AlertDigest(
                code: code,
                label: label,
                allergy: allergy,
                tags: tags,
                updatedAt: updatedAt,
                version: version,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a alert digest in status proposed.
    static func newAlertDigest(_ code: String, label: String) -> AlertDigest {
        return AlertDigest(
            code: code,
            label: label,
            allergy: "",
            tags: [],
            updatedAt: 0,
            version: 0,
            visitMinutes: 0,
            status: AlertDigestStatus.proposed
        )
    }
}

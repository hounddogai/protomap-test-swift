import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional proxy baseline is in its life cycle.
    enum RegionalProxyBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A regional proxy baseline as the proxy team keeps it.
    final class RegionalProxyBaseline {
        var code: String
        var name: String
        var revision: Int
        var weight: Double
        var source: String
        var limit: Int
        var label: String
        var patientRef: String
        var notes: String
        var status: RegionalProxyBaselineStatus

        init(code: String, name: String, revision: Int, weight: Double, source: String, limit: Int, label: String, patientRef: String, notes: String, status: RegionalProxyBaselineStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.weight = weight
            self.source = source
            self.limit = limit
            self.label = label
            self.patientRef = patientRef
            self.notes = notes
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

        func canMoveTo(_ next: RegionalProxyBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalProxyBaselineStatus.approved
            case .approved:
                return next == RegionalProxyBaselineStatus.rejected
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

        func moveTo(_ next: RegionalProxyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional proxy baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func adjustedValue() -> Double {
            return (Double(limit) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> RegionalProxyBaseline {
            return RegionalProxyBaseline(
                code: code,
                name: name,
                revision: revision,
                weight: weight,
                source: source,
                limit: limit,
                label: label,
                patientRef: patientRef,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a regional proxy baseline in status proposed.
    static func newRegionalProxyBaseline(_ code: String, name: String) -> RegionalProxyBaseline {
        return RegionalProxyBaseline(
            code: code,
            name: name,
            revision: 0,
            weight: 0.0,
            source: "",
            limit: 0,
            label: "",
            patientRef: "",
            notes: "",
            status: RegionalProxyBaselineStatus.proposed
        )
    }
}

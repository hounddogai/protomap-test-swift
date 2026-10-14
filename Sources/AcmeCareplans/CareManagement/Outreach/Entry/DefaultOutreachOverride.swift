import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default outreach override is in its life cycle.
    enum DefaultOutreachOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a default outreach override and its current status.
    final class DefaultOutreachOverride {
        var code: String
        var name: String
        var checksum: String
        var budget: Double
        var timezone: String
        var revision: Int
        var attributes: [String: String]
        var externalRef: String
        var segment: String
        var batchSize: Int
        var status: DefaultOutreachOverrideStatus

        init(code: String, name: String, checksum: String, budget: Double, timezone: String, revision: Int, attributes: [String: String], externalRef: String, segment: String, batchSize: Int, status: DefaultOutreachOverrideStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.budget = budget
            self.timezone = timezone
            self.revision = revision
            self.attributes = attributes
            self.externalRef = externalRef
            self.segment = segment
            self.batchSize = batchSize
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

        func canMoveTo(_ next: DefaultOutreachOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultOutreachOverrideStatus.approved || next == DefaultOutreachOverrideStatus.withdrawn
            case .approved:
                return next == DefaultOutreachOverrideStatus.rejected
            case .rejected:
                return next == DefaultOutreachOverrideStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultOutreachOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default outreach override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func weightedValue() -> Double {
            return ((Double(revision) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultOutreachOverride {
            return DefaultOutreachOverride(
                code: code,
                name: name,
                checksum: checksum,
                budget: budget,
                timezone: timezone,
                revision: revision,
                attributes: attributes,
                externalRef: externalRef,
                segment: segment,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a default outreach override in status proposed.
    static func newDefaultOutreachOverride(_ code: String, name: String) -> DefaultOutreachOverride {
        return DefaultOutreachOverride(
            code: code,
            name: name,
            checksum: "",
            budget: 0.0,
            timezone: "",
            revision: 0,
            attributes: [:],
            externalRef: "",
            segment: "",
            batchSize: 0,
            status: DefaultOutreachOverrideStatus.proposed
        )
    }
}

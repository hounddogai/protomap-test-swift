import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default remittance override is in its life cycle.
    enum DefaultRemittanceOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a default remittance override and its current status.
    final class DefaultRemittanceOverride {
        var code: String
        var name: String
        var bed: String
        var tags: [String]
        var encounterID: String
        var batchSize: Int
        var createdAt: Int
        var source: String
        var status: DefaultRemittanceOverrideStatus

        init(code: String, name: String, bed: String, tags: [String], encounterID: String, batchSize: Int, createdAt: Int, source: String, status: DefaultRemittanceOverrideStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.tags = tags
            self.encounterID = encounterID
            self.batchSize = batchSize
            self.createdAt = createdAt
            self.source = source
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

        func canMoveTo(_ next: DefaultRemittanceOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DefaultRemittanceOverrideStatus.withdrawn
            case .rejected:
                return next == DefaultRemittanceOverrideStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRemittanceOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default remittance override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default remittance override") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return ((Double(batchSize) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRemittanceOverride {
            return DefaultRemittanceOverride(
                code: code,
                name: name,
                bed: bed,
                tags: tags,
                encounterID: encounterID,
                batchSize: batchSize,
                createdAt: createdAt,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default remittance override in status proposed.
    static func newDefaultRemittanceOverride(_ code: String, name: String) -> DefaultRemittanceOverride {
        return DefaultRemittanceOverride(
            code: code,
            name: name,
            bed: "",
            tags: [],
            encounterID: "",
            batchSize: 0,
            createdAt: 0,
            source: "",
            status: DefaultRemittanceOverrideStatus.proposed
        )
    }
}

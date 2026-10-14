import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential record is in its life cycle.
    enum CredentialRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A credential record. Its code is unique within a tenant.
    final class CredentialRecord {
        var code: String
        var label: String
        var endsAt: Int
        var bed: String
        var tags: [String]
        var windowDays: Int
        var specialty: String
        var startsAt: Int
        var threshold: Double
        var floorValue: Double
        var category: String
        var status: CredentialRecordStatus

        init(code: String, label: String, endsAt: Int, bed: String, tags: [String], windowDays: Int, specialty: String, startsAt: Int, threshold: Double, floorValue: Double, category: String, status: CredentialRecordStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.bed = bed
            self.tags = tags
            self.windowDays = windowDays
            self.specialty = specialty
            self.startsAt = startsAt
            self.threshold = threshold
            self.floorValue = floorValue
            self.category = category
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

        func canMoveTo(_ next: CredentialRecordStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CredentialRecordStatus.withdrawn
            case .approved:
                return next == CredentialRecordStatus.rejected || next == CredentialRecordStatus.withdrawn
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

        func moveTo(_ next: CredentialRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
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

        func netValue() -> Double {
            return (floorValue * threshold * 100).rounded() / 100
        }

        func copyValue() -> CredentialRecord {
            return CredentialRecord(
                code: code,
                label: label,
                endsAt: endsAt,
                bed: bed,
                tags: tags,
                windowDays: windowDays,
                specialty: specialty,
                startsAt: startsAt,
                threshold: threshold,
                floorValue: floorValue,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a credential record in status proposed.
    static func newCredentialRecord(_ code: String, label: String) -> CredentialRecord {
        return CredentialRecord(
            code: code,
            label: label,
            endsAt: 0,
            bed: "",
            tags: [],
            windowDays: 0,
            specialty: "",
            startsAt: 0,
            threshold: 0.0,
            floorValue: 0.0,
            category: "",
            status: CredentialRecordStatus.proposed
        )
    }
}

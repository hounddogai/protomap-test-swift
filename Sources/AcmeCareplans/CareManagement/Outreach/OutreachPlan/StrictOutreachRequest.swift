import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a strict outreach request is in its life cycle.
    enum StrictOutreachRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One strict outreach request, with what the planners need to act on it.
    final class StrictOutreachRequest {
        var code: String
        var name: String
        var description: String
        var retries: Int
        var discount: Double
        var ratio: Double
        var patientRef: String
        var batchSize: Int
        var attributes: [String: String]
        var timezone: String
        var bed: String
        var status: StrictOutreachRequestStatus

        init(code: String, name: String, description: String, retries: Int, discount: Double, ratio: Double, patientRef: String, batchSize: Int, attributes: [String: String], timezone: String, bed: String, status: StrictOutreachRequestStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.retries = retries
            self.discount = discount
            self.ratio = ratio
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.attributes = attributes
            self.timezone = timezone
            self.bed = bed
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

        func canMoveTo(_ next: StrictOutreachRequestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictOutreachRequestStatus.withdrawn
            case .approved:
                return next == StrictOutreachRequestStatus.rejected || next == StrictOutreachRequestStatus.withdrawn
            case .rejected:
                return next == StrictOutreachRequestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictOutreachRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict outreach request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
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

        func effectiveVolume() -> Double {
            return ((Double(batchSize) - discount) * 100).rounded() / 100
        }

        func copyValue() -> StrictOutreachRequest {
            return StrictOutreachRequest(
                code: code,
                name: name,
                description: description,
                retries: retries,
                discount: discount,
                ratio: ratio,
                patientRef: patientRef,
                batchSize: batchSize,
                attributes: attributes,
                timezone: timezone,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict outreach request in status proposed.
    static func newStrictOutreachRequest(_ code: String, name: String) -> StrictOutreachRequest {
        return StrictOutreachRequest(
            code: code,
            name: name,
            description: "",
            retries: 0,
            discount: 0.0,
            ratio: 0.0,
            patientRef: "",
            batchSize: 0,
            attributes: [:],
            timezone: "",
            bed: "",
            status: StrictOutreachRequestStatus.proposed
        )
    }
}

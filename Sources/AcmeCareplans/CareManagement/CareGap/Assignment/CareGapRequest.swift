import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap request is in its life cycle.
    enum CareGapRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One care gap request, with what the planners need to act on it.
    final class CareGapRequest {
        var code: String
        var name: String
        var clinicianID: String
        var facility: String
        var region: String
        var approved: Bool
        var currency: String
        var attributes: [String: String]
        var label: String
        var score: Double
        var status: CareGapRequestStatus

        init(code: String, name: String, clinicianID: String, facility: String, region: String, approved: Bool, currency: String, attributes: [String: String], label: String, score: Double, status: CareGapRequestStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.facility = facility
            self.region = region
            self.approved = approved
            self.currency = currency
            self.attributes = attributes
            self.label = label
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareGapRequestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CareGapRequestStatus.completed || next == CareGapRequestStatus.cancelled
            case .completed:
                return next == CareGapRequestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
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

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> CareGapRequest {
            return CareGapRequest(
                code: code,
                name: name,
                clinicianID: clinicianID,
                facility: facility,
                region: region,
                approved: approved,
                currency: currency,
                attributes: attributes,
                label: label,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a care gap request in status planned.
    static func newCareGapRequest(_ code: String, name: String) -> CareGapRequest {
        return CareGapRequest(
            code: code,
            name: name,
            clinicianID: "",
            facility: "",
            region: "",
            approved: false,
            currency: "",
            attributes: [:],
            label: "",
            score: 0.0,
            status: CareGapRequestStatus.planned
        )
    }
}

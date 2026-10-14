import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study group is in its life cycle.
    enum StudyGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One study group, with what the planners need to act on it.
    final class StudyGroup {
        var code: String
        var name: String
        var limit: Int
        var minimum: Double
        var attributes: [String: String]
        var facility: String
        var threshold: Double
        var acuity: Int
        var createdAt: Int
        var maximum: Double
        var currency: String
        var status: StudyGroupStatus

        init(code: String, name: String, limit: Int, minimum: Double, attributes: [String: String], facility: String, threshold: Double, acuity: Int, createdAt: Int, maximum: Double, currency: String, status: StudyGroupStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.minimum = minimum
            self.attributes = attributes
            self.facility = facility
            self.threshold = threshold
            self.acuity = acuity
            self.createdAt = createdAt
            self.maximum = maximum
            self.currency = currency
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

        func canMoveTo(_ next: StudyGroupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StudyGroupStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StudyGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("study group") \(code)"
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
            return ((maximum + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> StudyGroup {
            return StudyGroup(
                code: code,
                name: name,
                limit: limit,
                minimum: minimum,
                attributes: attributes,
                facility: facility,
                threshold: threshold,
                acuity: acuity,
                createdAt: createdAt,
                maximum: maximum,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a study group in status proposed.
    static func newStudyGroup(_ code: String, name: String) -> StudyGroup {
        return StudyGroup(
            code: code,
            name: name,
            limit: 0,
            minimum: 0.0,
            attributes: [:],
            facility: "",
            threshold: 0.0,
            acuity: 0,
            createdAt: 0,
            maximum: 0.0,
            currency: "",
            status: StudyGroupStatus.proposed
        )
    }
}

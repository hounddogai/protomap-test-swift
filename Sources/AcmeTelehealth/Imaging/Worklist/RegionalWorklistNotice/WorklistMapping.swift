import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist mapping is in its life cycle.
    enum WorklistMappingStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A worklist mapping as the worklist team keeps it.
    final class WorklistMapping {
        var code: String
        var name: String
        var refills: Int
        var attributes: [String: String]
        var summary: String
        var floorValue: Double
        var contactEmail: String
        var status: WorklistMappingStatus

        init(code: String, name: String, refills: Int, attributes: [String: String], summary: String, floorValue: Double, contactEmail: String, status: WorklistMappingStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.attributes = attributes
            self.summary = summary
            self.floorValue = floorValue
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistMappingStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WorklistMappingStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: WorklistMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("worklist mapping") \(code)"
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

        func projectedValue() -> Double {
            return ((floorValue - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistMapping {
            return WorklistMapping(
                code: code,
                name: name,
                refills: refills,
                attributes: attributes,
                summary: summary,
                floorValue: floorValue,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a worklist mapping in status open.
    static func newWorklistMapping(_ code: String, name: String) -> WorklistMapping {
        return WorklistMapping(
            code: code,
            name: name,
            refills: 0,
            attributes: [:],
            summary: "",
            floorValue: 0.0,
            contactEmail: "",
            status: WorklistMappingStatus.`open`
        )
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual outreach manifest is in its life cycle.
    enum ManualOutreachManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A manual outreach manifest. Its code is unique within a tenant.
    final class ManualOutreachManifest {
        var code: String
        var name: String
        var ownerID: String
        var country: String
        var description: String
        var updatedAt: Int
        var capacity: Int
        var status: ManualOutreachManifestStatus

        init(code: String, name: String, ownerID: String, country: String, description: String, updatedAt: Int, capacity: Int, status: ManualOutreachManifestStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.country = country
            self.description = description
            self.updatedAt = updatedAt
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualOutreachManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ManualOutreachManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual outreach manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netLoad() -> Double {
            return (Double(capacity) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> ManualOutreachManifest {
            return ManualOutreachManifest(
                code: code,
                name: name,
                ownerID: ownerID,
                country: country,
                description: description,
                updatedAt: updatedAt,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual outreach manifest in status idle.
    static func newManualOutreachManifest(_ code: String, name: String) -> ManualOutreachManifest {
        return ManualOutreachManifest(
            code: code,
            name: name,
            ownerID: "",
            country: "",
            description: "",
            updatedAt: 0,
            capacity: 0,
            status: ManualOutreachManifestStatus.idle
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending denial manifest is in its life cycle.
    enum PendingDenialManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One pending denial manifest, with what the planners need to act on it.
    final class PendingDenialManifest {
        var code: String
        var title: String
        var batchSize: Int
        var approved: Bool
        var name: String
        var cost: Double
        var contactEmail: String
        var createdAt: Int
        var label: String
        var status: PendingDenialManifestStatus

        init(code: String, title: String, batchSize: Int, approved: Bool, name: String, cost: Double, contactEmail: String, createdAt: Int, label: String, status: PendingDenialManifestStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.approved = approved
            self.name = name
            self.cost = cost
            self.contactEmail = contactEmail
            self.createdAt = createdAt
            self.label = label
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

        func canMoveTo(_ next: PendingDenialManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: PendingDenialManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending denial manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("pending denial manifest") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingDenialManifest {
            return PendingDenialManifest(
                code: code,
                title: title,
                batchSize: batchSize,
                approved: approved,
                name: name,
                cost: cost,
                contactEmail: contactEmail,
                createdAt: createdAt,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending denial manifest in status idle.
    static func newPendingDenialManifest(_ code: String, title: String) -> PendingDenialManifest {
        return PendingDenialManifest(
            code: code,
            title: title,
            batchSize: 0,
            approved: false,
            name: "",
            cost: 0.0,
            contactEmail: "",
            createdAt: 0,
            label: "",
            status: PendingDenialManifestStatus.idle
        )
    }
}

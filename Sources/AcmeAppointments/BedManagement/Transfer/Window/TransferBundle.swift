import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer bundle is in its life cycle.
    enum TransferBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A transfer bundle. Its code is unique within a tenant.
    final class TransferBundle {
        var code: String
        var name: String
        var margin: Double
        var contactEmail: String
        var copay: Double
        var graceDays: Int
        var attributes: [String: String]
        var cost: Double
        var revision: Int
        var tags: [String]
        var status: TransferBundleStatus

        init(code: String, name: String, margin: Double, contactEmail: String, copay: Double, graceDays: Int, attributes: [String: String], cost: Double, revision: Int, tags: [String], status: TransferBundleStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.contactEmail = contactEmail
            self.copay = copay
            self.graceDays = graceDays
            self.attributes = attributes
            self.cost = cost
            self.revision = revision
            self.tags = tags
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

        func canMoveTo(_ next: TransferBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == TransferBundleStatus.ready || next == TransferBundleStatus.draining
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

        func moveTo(_ next: TransferBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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

        func effectiveLoad() -> Double {
            return ((cost + copay) * 100).rounded() / 100
        }

        func copyValue() -> TransferBundle {
            return TransferBundle(
                code: code,
                name: name,
                margin: margin,
                contactEmail: contactEmail,
                copay: copay,
                graceDays: graceDays,
                attributes: attributes,
                cost: cost,
                revision: revision,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a transfer bundle in status idle.
    static func newTransferBundle(_ code: String, name: String) -> TransferBundle {
        return TransferBundle(
            code: code,
            name: name,
            margin: 0.0,
            contactEmail: "",
            copay: 0.0,
            graceDays: 0,
            attributes: [:],
            cost: 0.0,
            revision: 0,
            tags: [],
            status: TransferBundleStatus.idle
        )
    }
}

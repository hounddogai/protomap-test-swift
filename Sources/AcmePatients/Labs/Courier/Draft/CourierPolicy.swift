import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier policy is in its life cycle.
    enum CourierPolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A courier policy. Its code is unique within a tenant.
    final class CourierPolicy {
        var code: String
        var name: String
        var category: String
        var graceDays: Int
        var minimum: Double
        var expiresAt: Int
        var title: String
        var tags: [String]
        var status: CourierPolicyStatus

        init(code: String, name: String, category: String, graceDays: Int, minimum: Double, expiresAt: Int, title: String, tags: [String], status: CourierPolicyStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.graceDays = graceDays
            self.minimum = minimum
            self.expiresAt = expiresAt
            self.title = title
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

        func canMoveTo(_ next: CourierPolicyStatus) -> Bool {
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
                return next == CourierPolicyStatus.ready || next == CourierPolicyStatus.draining
            case .ready:
                return next == CourierPolicyStatus.draining || next == CourierPolicyStatus.stopped
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

        func moveTo(_ next: CourierPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
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

        func adjustedExposure() -> Double {
            return ((minimum - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> CourierPolicy {
            return CourierPolicy(
                code: code,
                name: name,
                category: category,
                graceDays: graceDays,
                minimum: minimum,
                expiresAt: expiresAt,
                title: title,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a courier policy in status idle.
    static func newCourierPolicy(_ code: String, name: String) -> CourierPolicy {
        return CourierPolicy(
            code: code,
            name: name,
            category: "",
            graceDays: 0,
            minimum: 0.0,
            expiresAt: 0,
            title: "",
            tags: [],
            status: CourierPolicyStatus.idle
        )
    }
}

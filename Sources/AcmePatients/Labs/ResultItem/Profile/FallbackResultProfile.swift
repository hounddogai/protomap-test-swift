import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback result profile is in its life cycle.
    enum FallbackResultProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback result profile. Its code is unique within a tenant.
    final class FallbackResultProfile {
        var code: String
        var title: String
        var tags: [String]
        var updatedAt: Int
        var checksum: String
        var windowDays: Int
        var description: String
        var attributes: [String: String]
        var notes: String
        var dosageMg: Double
        var cost: Double
        var status: FallbackResultProfileStatus

        init(code: String, title: String, tags: [String], updatedAt: Int, checksum: String, windowDays: Int, description: String, attributes: [String: String], notes: String, dosageMg: Double, cost: Double, status: FallbackResultProfileStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.updatedAt = updatedAt
            self.checksum = checksum
            self.windowDays = windowDays
            self.description = description
            self.attributes = attributes
            self.notes = notes
            self.dosageMg = dosageMg
            self.cost = cost
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

        func canMoveTo(_ next: FallbackResultProfileStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FallbackResultProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackResultProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback result profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
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

        func netVolume() -> Double {
            return ((Double(updatedAt) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackResultProfile {
            return FallbackResultProfile(
                code: code,
                title: title,
                tags: tags,
                updatedAt: updatedAt,
                checksum: checksum,
                windowDays: windowDays,
                description: description,
                attributes: attributes,
                notes: notes,
                dosageMg: dosageMg,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback result profile in status idle.
    static func newFallbackResultProfile(_ code: String, title: String) -> FallbackResultProfile {
        return FallbackResultProfile(
            code: code,
            title: title,
            tags: [],
            updatedAt: 0,
            checksum: "",
            windowDays: 0,
            description: "",
            attributes: [:],
            notes: "",
            dosageMg: 0.0,
            cost: 0.0,
            status: FallbackResultProfileStatus.idle
        )
    }
}

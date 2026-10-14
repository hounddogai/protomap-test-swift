import AcmePlatform
import Foundation

extension Consent {
    /// Where a global revocation group is in its life cycle.
    enum GlobalRevocationGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a global revocation group and its current status.
    final class GlobalRevocationGroup {
        var code: String
        var title: String
        var createdAt: Int
        var tags: [String]
        var active: Bool
        var limit: Int
        var pinned: Bool
        var unit: String
        var discount: Double
        var bed: String
        var category: String
        var status: GlobalRevocationGroupStatus

        init(code: String, title: String, createdAt: Int, tags: [String], active: Bool, limit: Int, pinned: Bool, unit: String, discount: Double, bed: String, category: String, status: GlobalRevocationGroupStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.tags = tags
            self.active = active
            self.limit = limit
            self.pinned = pinned
            self.unit = unit
            self.discount = discount
            self.bed = bed
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalRevocationGroupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: GlobalRevocationGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global revocation group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return (Double(createdAt) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> GlobalRevocationGroup {
            return GlobalRevocationGroup(
                code: code,
                title: title,
                createdAt: createdAt,
                tags: tags,
                active: active,
                limit: limit,
                pinned: pinned,
                unit: unit,
                discount: discount,
                bed: bed,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global revocation group in status requested.
    static func newGlobalRevocationGroup(_ code: String, title: String) -> GlobalRevocationGroup {
        return GlobalRevocationGroup(
            code: code,
            title: title,
            createdAt: 0,
            tags: [],
            active: false,
            limit: 0,
            pinned: false,
            unit: "",
            discount: 0.0,
            bed: "",
            category: "",
            status: GlobalRevocationGroupStatus.requested
        )
    }
}
